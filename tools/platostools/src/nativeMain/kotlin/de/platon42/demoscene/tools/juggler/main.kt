package de.platon42.demoscene.tools.juggler

import kotlinx.cinterop.*
import kotlinx.cli.ArgParser
import kotlinx.cli.ArgType
import kotlinx.cli.ExperimentalCli
import kotlinx.cli.Subcommand
import platform.posix.*

@OptIn(ExperimentalUnsignedTypes::class)
fun loadFile(filename: String): UByteArray? {
    val file = fopen(filename, "rb")
    if (file == null) {
        perror("cannot read file $filename")
        return null
    }
    memScoped {
        fseek(file, 0, SEEK_END)
        val expectedSize = ftell(file)
        fseek(file, 0, SEEK_SET)
        val image = allocArray<UByteVar>(expectedSize)
        val size = fread(image, expectedSize.toULong(), 1UL, file)
        fclose(file)
        //println("Read file $filename ($expectedSize bytes)")
        return UByteArray(expectedSize.toInt()) { image[it] }
    }
}

@OptIn(ExperimentalUnsignedTypes::class)
fun saveFile(filename: String, data: UByteArray) {
    val file = fopen(filename, "wb")
    if (file == null) {
        perror("cannot write file $filename")
        return
    }
    memScoped {
        val image = allocArray<UByteVar>(data.size)
        for (i in data.indices) {
            image[i] = data[i]
        }
        val size = fwrite(image, data.size.toULong(), 1UL, file)
        //println("Saved ${data.size} bytes to $filename")
        fclose(file)
    }
}

@OptIn(ExperimentalUnsignedTypes::class)
fun main(args: Array<String>) {
    val argParser = ArgParser("juggler")

    val rootDirectoryOption by argParser.option(
        ArgType.String,
        "root",
        shortName = "r",
        description = "Root directory"
    )

    val layoutFileName by argParser.argument(ArgType.String, "layout", description = "Layout description file")

    try {
        argParser.parse(args)
    } catch (ex: IllegalStateException) {
        println(ex.message)
        exit(-1)
    }

    val rootDirectory = if (rootDirectoryOption != null) "$rootDirectoryOption/" else ""

    val layoutBinary = loadFile(rootDirectory + layoutFileName) ?: throw IllegalStateException("Missing layout file!")
    val layoutText = CharArray(layoutBinary.size) { layoutBinary[it].toInt().toChar() }
        .concatToString()
        .split("\n")
        .filter { it.isNotBlank() && !it.startsWith("//") }

    var data = UByteArray(0)
    for (line in layoutText) {
        data = parseLayoutLine(line, rootDirectory, data)
    }
}

@ExperimentalCli
@OptIn(ExperimentalUnsignedTypes::class)
private fun parseLayoutLine(
    line: String,
    rootDirectory: String,
    data: UByteArray,
): UByteArray {
    val lineParser = ArgParser("layoutfile")

    var newData = data

    class ClearCommand : Subcommand("clear", "Clear buffers") {
        override fun execute() {
            newData = UByteArray(0)
            println("Cleared buffer.")
        }
    }

    abstract class LoadSaveCommand(name: String, actionDescription: String, fileDesc: String) :
        Subcommand(name, actionDescription) {
        val filename by argument(ArgType.String, "filename", description = fileDesc)
        val start by option(ArgType.Int, "start", "s", description = "Start offset in bytes")
        val fromEnd by option(ArgType.Int, "fromEnd", "e", description = "Offset from end in bytes (instead of start)")
        val length by option(ArgType.Int, "length", "l", description = "Length in bytes (or chunk size)")
        val chunk by option(ArgType.Int, "chunk", "n", description = "Chunk number")

        var startOff = 0
        var newLength = 0

        fun parseInfo(filesize: Int) {
            startOff = 0
            newLength = filesize
            if (start != null) {
                if (start!! >= newLength) {
                    perror("$start is past end of file '$filename' ($newLength bytes)!")
                    startOff = newLength
                    newLength = 0
                } else {
                    startOff = start!!
                    newLength -= startOff
                }
            }
            if (fromEnd != null) {
                if (fromEnd!! >= newLength) {
                    perror("$fromEnd is before beginning of file '$filename' ($newLength bytes)!")
                    startOff = 0
                } else {
                    startOff = newLength - fromEnd!!
                    newLength = fromEnd!!
                }
            }
            if (chunk == null && length != null) {
                if (length!! > newLength - startOff) {
                    perror("$length is larger than possible for file '$filename' (${filesize} bytes, start $startOff)!")
                    newLength -= startOff
                } else {
                    newLength = length!!
                }
            }
            if (chunk != null) {
                if (length != null) {
                    if (chunk!! * length!! >= newLength) {
                        perror("Chunk $chunk is past end of file '$filename' (${filesize} bytes, start $startOff)!")
                        newLength = 0
                    } else {
                        startOff += chunk!! * length!!
                        newLength = if (startOff + length!! > filesize) {
                            perror("Chunk $chunk is truncated for file '$filename' (${filesize} bytes, start $startOff)!")
                            filesize - (startOff + length!!)
                        } else {
                            length!!
                        }
                    }
                } else {
                    perror("Missing length option to be able to use the chunk option!")
                }
            }
        }
    }

    class LoadCommand : LoadSaveCommand("load", "Load a file (or a part)", "Input file") {
        override fun execute() {
            val wholeFile = loadFile(rootDirectory + filename) ?: return
            parseInfo(wholeFile.size)

            newData = data.plus(wholeFile.sliceArray(startOff until startOff + newLength))
            println("Loaded $newLength bytes at offset $startOff (new size ${newData.size}).")
        }
    }

    class SaveCommand : LoadSaveCommand("save", "Save a file (or a part)", "Output file") {
        override fun execute() {
            parseInfo(data.size)

            val savePart = data.sliceArray(startOff until startOff + newLength)
            saveFile(rootDirectory + filename, savePart)
            println("Saved ${savePart.size} bytes from offset $startOff.")
        }
    }

    class ExtractCommand : LoadSaveCommand("extract", "Extract a portion of the current buffer", "Dummy") {
        override fun execute() {
            parseInfo(data.size)

            newData = data.sliceArray(startOff until startOff + newLength)
            println("Extracted ${newData.size} bytes from offset $startOff.")
        }
    }

    class ReorganizeCommand :
        Subcommand("reorganize", "Reorganize array in a different way") {
        val height by argument(ArgType.Int, "height", description = "Outer length")
        val widthOption by option(ArgType.Int, "width", "w", description = "Inner length (default: 1)")
        val unitLenOption by option(ArgType.Int, "unitlength", "l", description = "Length of a unit (default: 1)")
        val unitModOption by option(ArgType.Int, "unitmod", "um", description = "Space between units (default: 0)")
        val rowModOption by option(ArgType.Int, "rowmod", "rm", description = "Space after a row (default: 0)")
        val startOffOption by option(ArgType.Int, "start", "s", description = "Start offset in bytes (default: 0)")

        override fun execute() {
            val unitLen = unitLenOption ?: 1
            val width = widthOption ?: 1
            val unitMod = unitModOption ?: 0
            val rowMod = rowModOption ?: 0
            newData = UByteArray(height * width * unitLen)
            var inPos = startOffOption ?: 0
            var outPos = 0
            outer@ for (row in 1..height) {
                for (column in 1..width) {
                    if (inPos >= data.size) {
                        println("Out of data at output position $outPos (row=$row, column=$column)")
                        break@outer
                    }
                    data.copyInto(newData, outPos, inPos, inPos + unitLen)
                    outPos += unitLen
                    inPos += unitLen + unitMod
                }
                inPos += rowMod
            }
            println("Reorganized data to ${newData.size} bytes.")
        }

    }
    lineParser.subcommands(ClearCommand(), LoadCommand(), SaveCommand(), ExtractCommand(), ReorganizeCommand())
    println(line)
    lineParser.parse(line.split(" ").toTypedArray())
    return newData
}