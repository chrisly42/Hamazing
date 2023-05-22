package de.platon42.demoscene.tools.platosadf

import kotlinx.cinterop.*
import kotlinx.cli.ArgParser
import kotlinx.cli.ArgType
import kotlinx.coroutines.*
import platform.posix.*

const val HUNK_HEADER = 0x3f3U
const val HUNK_CODE = 0x3e9U
const val HUNK_DATA = 0x3eaU
const val HUNK_BSS = 0x3ebU
const val HUNK_RELOC32 = 0x3ecU
const val HUNK_END = 0x3f2U

const val MEM_ANY = 0U
const val MEM_CHIP = 1U
const val MEM_FAST = 2U

const val DEFF_MORE_HUNKS = (1 shl 15)
const val DEFF_CHIPMEM = (1 shl 7)
const val DEFF_DATAFILE = (0 shl 0)
const val DEFF_HUNK_CODE = (1 shl 0)
const val DEFF_HUNK_DATA = (2 shl 0)
const val DEFF_HUNK_BSS = (3 shl 0)
const val DEFF_HUNK_RELOC = (4 shl 0)
const val DEFF_UNPACKED = (0 shl 4)
const val DEFF_LZ4 = (1 shl 4)
const val DEFF_DOYNAX = (2 shl 4)
const val DEFF_ZX0 = (3 shl 4)
const val DEFF_DELTA8 = (1 shl 8)
const val DEFF_DELTA16 = (2 shl 8)
const val DEFF_DELTA32 = (3 shl 8)

const val DEFF_IN_PLACE = (1 shl 11)

const val toolsdir = ""

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

var imageSize = 11 * 160 * 512

@OptIn(ExperimentalUnsignedTypes::class)
fun UByteArray.readLong(offset: Int): UInt {
    return (this[offset].toUInt() shl 24) or (this[offset + 1].toUInt() shl 16) or (this[offset + 2].toUInt() shl 8) or (this[offset + 3].toUInt())
}

@OptIn(ExperimentalUnsignedTypes::class)
fun UByteArray.readWord(offset: Int): UInt {
    return (this[offset].toUInt() shl 8) or (this[offset + 1].toUInt())
}

@OptIn(ExperimentalUnsignedTypes::class)
fun UByteArray.writeLong(offset: Int, value: UInt) {
    this[offset] = (value shr 24).toUByte()
    this[offset + 1] = (value shr 16).toUByte()
    this[offset + 2] = (value shr 8).toUByte()
    this[offset + 3] = value.toUByte()
}

@OptIn(ExperimentalUnsignedTypes::class)
fun UByteArray.writeWord(offset: Int, value: UInt) {
    this[offset] = (value shr 8).toUByte()
    this[offset + 1] = value.toUByte()
}

@OptIn(ExperimentalUnsignedTypes::class)
fun patchBootblockChecksum(adf: UByteArray) {
    var chksum = 0UL
    adf.writeLong(4, 0U)
    for (i in 0..255) {
        val longval = adf.readLong(i * 4)
        chksum += longval
        if (chksum >= (1UL shl 32)) {
            chksum -= (1UL shl 32) - 1UL
        }
    }
    chksum = chksum xor 0xffffffffUL
    adf.writeLong(4, chksum.toUInt())
}

enum class FileEntryFlags {
    CHIPMEM,
    DATAFILE,
    CODE_HUNK,
    DATA_HUNK,
    BSS_HUNK,
    RELOC_HUNK,
    LZ4,
    DOYNAX,
    ZX0,
    ZSTD,
    BEST_COMPRESSION,
    DELTA8,
    DELTA16,
    FAST
}

@OptIn(ExperimentalUnsignedTypes::class)
data class FileEntry(
    val data: UByteArray,
    val name: String,
    val flags: Set<FileEntryFlags>,
    val memorysize: Int,
    var diskoffset: Int = 0,
    val hunkNum: Int = 0,
    val numHunks: Int = 0
)

@OptIn(ExperimentalUnsignedTypes::class)
fun main(args: Array<String>) {
    val argParser = ArgParser("platosadf")

    val rootDirectoryOption by argParser.option(
        ArgType.String,
        "root",
        shortName = "r",
        description = "Root directory"
    )

    val bootOnlyOption by argParser.option(
        ArgType.Boolean,
        "bootOnly",
        shortName = "b",
        description = "Only create ADF with bootblock"
    )

    val numDirBlocksOption by argParser.option(
        ArgType.Int,
        "numDirBlocks",
        shortName = "ndb",
        description = "Number of directory blocks to use (default 1)"
    )

    val imageSizeOption by argParser.option(
        ArgType.Int,
        "imageSize",
        shortName = "is",
        description = "Maximum image size in blocks (default 1760)"
    )

    val diskLabelOption by argParser.option(
        ArgType.String,
        "label",
        shortName = "l",
        description = "Disk label in bootblock (8 characters, default: PLATON42)"
    )

    val truncateOption by argParser.option(
        ArgType.Boolean,
        "truncate",
        shortName = "t",
        description = "Truncate disk image to actual used size (rounded to blocks)"
    )

    val fastOption by argParser.option(
        ArgType.Boolean,
        "fast",
        shortName = "f",
        description = "Do fast compression (may not be optimal)"
    )

    val sequentialOption by argParser.option(
        ArgType.Boolean,
        "singlethread",
        shortName = "sth",
        description = "Don't use parallel file packing"
    )

    if (imageSizeOption != null) {
        imageSize = imageSizeOption!! * 512
    }
    val diskimage = UByteArray(imageSize) { 0u }

    val adfTargetFileName by argParser.argument(ArgType.String, "adf", description = "Target ADF image")
    val bootblockFileName by argParser.argument(ArgType.String, "bootblock", description = "Bootblock file")
    val layoutFileName by argParser.argument(ArgType.String, "layout", description = "Layout description file")

    try {
        argParser.parse(args)
    } catch (ex: IllegalStateException) {
        println(ex.message)
        exit(-1)
    }

    val rootDirectory = if (rootDirectoryOption != null) "$rootDirectoryOption/" else ""

    val bootblock = loadFile(rootDirectory + bootblockFileName) ?: throw IllegalStateException("Bootblock not found!")
    if (((bootblock.size > 508) && (bootOnlyOption == null)) || bootblock.size > 1024) {
        throw IllegalStateException("Bootblock too large!")
    }
    bootblock.copyInto(diskimage, destinationOffset = 0)

    if (bootOnlyOption != null) {
        patchBootblockChecksum(diskimage)
        saveFile(rootDirectory + adfTargetFileName, diskimage)
        return
    }
    var diskLabel1 = 0x504c4154U
    if (diskLabelOption != null) {
        val diskLabelString = diskLabelOption!!
        if (diskLabelString.length == 8) {
            diskLabel1 =
                (diskLabelString[0].code.toUByte().toUInt() shl 24) or
                        (diskLabelString[1].code.toUByte().toUInt() shl 16) or
                        (diskLabelString[2].code.toUByte().toUInt() shl 8) or
                        diskLabelString[3].code.toUByte().toUInt()
            for (i in 4..7) {
                diskimage[i + 4] = diskLabelString[i].code.toUByte()
            }
        } else {
            println("Disklabel does not consist of 8 characters, ignoring.")
        }
    }

    val layoutBinary = loadFile(rootDirectory + layoutFileName) ?: throw IllegalStateException("Missing layout file!")
    val layoutText = CharArray(layoutBinary.size) { layoutBinary[it].toInt().toChar() }
        .concatToString()
        .split("\n")
        .filter { it.isNotBlank() && !it.startsWith("//") }

    // create the (packed) files

    val filetable = ArrayList<FileEntry>()
    val fileEntrySets = Array<List<FileEntry>>(layoutText.size) { emptyList() }

    val dispatcher = Dispatchers.IO
    if (sequentialOption != true) {
        runBlocking {
            val workers = ArrayList<Deferred<Pair<Int, List<FileEntry>>>>()
            for (line in layoutText.withIndex()) {
                val worker = async(dispatcher) {
                    line.index to parseLayoutLine(line.value, rootDirectory, fastOption == true)
                }
                workers.add(worker)
            }
            for (worker in workers) {
                val pair = worker.await()
                fileEntrySets[pair.first] = pair.second
            }
        }
    } else {
        for (line in layoutText.withIndex()) {
            fileEntrySets[line.index] = parseLayoutLine(line.value, rootDirectory, fastOption == true)
        }
    }
    var diskoffset = 0
    for (entrySet in fileEntrySets) {
        var entrySize = 0
        for (entry in entrySet) {
            entry.diskoffset += diskoffset
            entrySize += (entry.data.size + 1) and -2
            filetable.add(entry)
        }
        diskoffset += entrySize
    }

    val numDirBlocks = numDirBlocksOption ?: 1

    val startoffset = 512 + numDirBlocks * 512
    val freeBytes = imageSize - (startoffset + diskoffset)
    println(
        "${filetable.size} entries in image ${startoffset + diskoffset} of $imageSize used " +
                "(${freeBytes} (${freeBytes / 1024} KB) free)"
    )
    if (freeBytes < 0) {
        println("Disk is full!")
        exit(-1)
    }
    val directoryEntriesOffset = 512
    var fileentryOffset = directoryEntriesOffset
    var lastname: String? = null
    var uncompressedData = 0
    var chiphunk = 0
    var fasthunk = 0

    for ((entrynum, fileentry) in filetable.withIndex()) {
        val containsData = fileentry.data.isNotEmpty()
        val finaldiskoffset = if (containsData) startoffset + fileentry.diskoffset else 0
        var flags = 0
        var flagsString: String
        if (finaldiskoffset != 0) uncompressedData += fileentry.memorysize
        if (lastname != fileentry.name) {
            chiphunk = 0
            fasthunk = 0
        }
        if (fileentry.flags.contains(FileEntryFlags.CHIPMEM)) {
            flagsString = "CHIP"
            flags = flags or DEFF_CHIPMEM
            chiphunk += fileentry.memorysize
        } else {
            flagsString = "FAST"
            fasthunk += fileentry.memorysize
        }
        if (fileentry.flags.contains(FileEntryFlags.DATAFILE)) {
            flagsString += " DATA      "
            flags = flags or DEFF_DATAFILE
        }
        if (fileentry.flags.contains(FileEntryFlags.CODE_HUNK)) {
            flagsString += " HUNK CODE "
            flags = flags or DEFF_HUNK_CODE
        }
        if (fileentry.flags.contains(FileEntryFlags.DATA_HUNK)) {
            flagsString += " HUNK DATA "
            flags = flags or DEFF_HUNK_DATA
        }
        if (fileentry.flags.contains(FileEntryFlags.BSS_HUNK)) {
            flagsString += " HUNK BSS  "
            flags = flags or DEFF_HUNK_BSS
        }
        if (fileentry.flags.contains(FileEntryFlags.RELOC_HUNK)) {
            flagsString += " HUNK RELOC"
            flags = flags or DEFF_HUNK_RELOC
        }
        if (containsData && fileentry.flags.contains(FileEntryFlags.LZ4)) {
            flagsString += " LZ4"
            flags = flags or DEFF_LZ4
        }
        if (containsData && fileentry.flags.contains(FileEntryFlags.ZX0)) {
            flagsString += " ZX0 IN-PLACE"
            flags = flags or DEFF_ZX0 or DEFF_IN_PLACE
        }
        if (containsData && fileentry.flags.contains(FileEntryFlags.DOYNAX)) {
            flagsString += " DOYNAX"
            flags = flags or DEFF_DOYNAX
        }
        if (containsData && fileentry.flags.contains(FileEntryFlags.DELTA8)) {
            flagsString += " DELTA8"
            flags = flags or DEFF_DELTA8
        }
        println(
            "${entrynum.toString().padStart(2)}: " +
                    "${finaldiskoffset.toString().padStart(6)} ${fileentry.name.padEnd(16)} " +
                    "${fileentry.data.size.toString().padStart(7)} " +
                    "${fileentry.hunkNum}/${fileentry.numHunks} " +
                    "${fileentry.memorysize.toString().padStart(7)} | " +
                    "${(chiphunk / 1024).toString().padStart(3)} KB CHIP | " +
                    "${(fasthunk / 1024).toString().padStart(3)} KB FAST | " +
                    flagsString
        )

        if (containsData) {
            fileentry.data.copyInto(diskimage, destinationOffset = finaldiskoffset)
        }
        if (lastname != fileentry.name) {
            for (i in 0 until (fileentry.name.length.coerceAtMost(16))) {
                diskimage[fileentryOffset + i] = fileentry.name[i].code.toUByte()
            }
            lastname = fileentry.name
        } else {
            if (entrynum > 0) {
                diskimage.writeWord(
                    fileentryOffset - 16,
                    diskimage.readWord(fileentryOffset - 16) or DEFF_MORE_HUNKS.toUInt()
                )
            }
            fileentryOffset -= 16
        }
        diskimage.writeWord(fileentryOffset + 16, flags.toUInt())
        diskimage[fileentryOffset + 18] = fileentry.hunkNum.toUByte()
        diskimage[fileentryOffset + 19] = fileentry.numHunks.toUByte()
        diskimage.writeLong(fileentryOffset + 20, fileentry.memorysize.toUInt())
        diskimage.writeLong(fileentryOffset + 24, finaldiskoffset.toUInt())
        diskimage.writeLong(fileentryOffset + 28, fileentry.data.size.toUInt())
        fileentryOffset += 32
    }
    if (fileentryOffset >= directoryEntriesOffset + numDirBlocks * 512) {
        println("Not enough space in directory table. Increase number of directory blocks!")
        exit(-1)
    }
    println("Total size uncompressed: $uncompressedData (${uncompressedData / 1024} KB)")

    patchBootblockChecksum(diskimage)
    val primaryChecksum = diskimage.readLong(4)
    diskimage.writeLong(directoryEntriesOffset - 4, primaryChecksum + (diskLabel1 xor 0xffffffffU) + 1U)
    patchBootblockChecksum(diskimage)
    if (diskimage.readLong(4) != diskLabel1) {
        diskimage.writeLong(directoryEntriesOffset - 4, primaryChecksum + (diskLabel1 xor 0xffffffffU))
        patchBootblockChecksum(diskimage)
    }
    if (diskimage.readLong(4) != diskLabel1) {
        println("Bootblock checksum not cool!")
    }

    if (truncateOption == true) {
        saveFile(rootDirectory + adfTargetFileName, diskimage.copyOf((((startoffset + diskoffset) + 511) / 512) * 512))
    } else {
        saveFile(rootDirectory + adfTargetFileName, diskimage)
    }
}

private fun removeAllCompressionFlags(fileFlags: MutableSet<FileEntryFlags>) {
    fileFlags.remove(FileEntryFlags.LZ4)
    fileFlags.remove(FileEntryFlags.DOYNAX)
    fileFlags.remove(FileEntryFlags.ZX0)
    fileFlags.remove(FileEntryFlags.ZSTD)
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun compressFile(
    filename: String,
    fileFlags: MutableSet<FileEntryFlags>,
    rootDirectory: String, data: UByteArray
): UByteArray? {
    val tmpfileName = rootDirectory + filename + ".tmp"
    //println("Compressing to $tmpfileName")
    val targetFileData =
        if (fileFlags.contains(FileEntryFlags.DELTA8) && !fileFlags.contains(FileEntryFlags.BEST_COMPRESSION)) {
            createDelta8EncodedData(data)
        } else {
            fileFlags.remove(FileEntryFlags.DELTA8)
            data
        }
    saveFile(tmpfileName, targetFileData)
    val thresholdSize = targetFileData.size - 16
    val compressedData = performCompression(rootDirectory, tmpfileName, thresholdSize, fileFlags)

    if (fileFlags.contains(FileEntryFlags.BEST_COMPRESSION)) {
        val deltaTargetFileData = createDelta8EncodedData(data)
        saveFile(tmpfileName, deltaTargetFileData)
        val deltaCompressedData =
            performCompression(rootDirectory, tmpfileName, compressedData?.size ?: thresholdSize, fileFlags)
        if (deltaCompressedData != null) {
            fileFlags.add(FileEntryFlags.DELTA8)
            return deltaCompressedData
        }
    }
    if (compressedData == null) {
        removeAllCompressionFlags(fileFlags)
    }
    unlink(tmpfileName)
    return compressedData
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun performCompression(
    rootDirectory: String,
    tmpfileName: String,
    thresholdSize: Int,
    fileFlags: MutableSet<FileEntryFlags>
): UByteArray? {
    var dataOut: UByteArray? = null
    if (fileFlags.contains(FileEntryFlags.ZX0) || fileFlags.contains(FileEntryFlags.BEST_COMPRESSION)) {
        dataOut = compressZx0(rootDirectory, tmpfileName, dataOut?.size ?: thresholdSize, fileFlags) ?: dataOut
    }
    if (fileFlags.contains(FileEntryFlags.DOYNAX) || fileFlags.contains(FileEntryFlags.BEST_COMPRESSION)) {
        dataOut = compressDoynax(rootDirectory, tmpfileName, dataOut?.size ?: thresholdSize, fileFlags) ?: dataOut
    }
    if (fileFlags.contains(FileEntryFlags.LZ4)) {
        dataOut = compressLz4(rootDirectory, tmpfileName, dataOut?.size ?: thresholdSize, fileFlags) ?: dataOut
    }
    if (fileFlags.contains(FileEntryFlags.ZSTD)) {
        dataOut = compressZStd(rootDirectory, tmpfileName, dataOut?.size ?: thresholdSize, fileFlags) ?: dataOut
    }
    return dataOut
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun compressZStd(
    rootDirectory: String,
    tmpfileName: String,
    thresholdSize: Int,
    fileFlags: MutableSet<FileEntryFlags>
): UByteArray? {
    val bonusparams = "--ultra -22 -f"
    val errno =
        system("${rootDirectory}${toolsdir}zstd $bonusparams $tmpfileName")
    if (errno != 0) println("ZSTD command failed")
    val zstdCompressedFile =
        loadFile(tmpfileName + ".zst") ?: throw IllegalStateException("Failed to load zst compressed file")
    val result = if (zstdCompressedFile.size < thresholdSize) {
        removeAllCompressionFlags(fileFlags)
        fileFlags.add(FileEntryFlags.ZSTD)
        zstdCompressedFile
    } else {
        null
    }
    unlink("$tmpfileName.zst")
    return result
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun compressLz4(
    rootDirectory: String,
    tmpfileName: String,
    thresholdSize: Int,
    fileFlags: MutableSet<FileEntryFlags>
): UByteArray? {
    val bonusparams = "-12 -BD --no-frame-crc -z -f"
    val errno =
        system("${rootDirectory}${toolsdir}lz4 $bonusparams $tmpfileName")
    if (errno != 0) println("LZ4 command failed")
    val lz4CompressedFile =
        loadFile("$tmpfileName.lz4") ?: throw IllegalStateException("Failed to load lz4 compressed hunk")
    val lz4CompressedBlock = lz4CompressedFile.copyOfRange(4 + 7, lz4CompressedFile.size - 4) // unwrap frame

    val result = if (lz4CompressedBlock.size < thresholdSize) {
        removeAllCompressionFlags(fileFlags)
        fileFlags.add(FileEntryFlags.LZ4)
        lz4CompressedBlock
    } else {
        null
    }

    unlink("$tmpfileName.lz4")
    return result
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun compressZx0(
    rootDirectory: String,
    tmpfileName: String,
    thresholdSize: Int,
    fileFlags: MutableSet<FileEntryFlags>,
): UByteArray? {
    if (fileFlags.contains(FileEntryFlags.FAST)) {
        val errno =
            system("${rootDirectory}${toolsdir}salvador $tmpfileName $tmpfileName.zx0")
        if (errno != 0) println("salvador command failed")
    } else {
        val bonusparams = "-f"
        val errno =
            system("${rootDirectory}${toolsdir}zx0 $bonusparams $tmpfileName")
        if (errno != 0) println("ZX0 command failed")
    }

    val zx0CompressedFile =
        loadFile("$tmpfileName.zx0") ?: throw IllegalStateException("Failed to load zx0 compressed hunk")

    val result = if (zx0CompressedFile.size < thresholdSize) {
        removeAllCompressionFlags(fileFlags)
        fileFlags.add(FileEntryFlags.ZX0)
        zx0CompressedFile
    } else {
        null
    }

    unlink("$tmpfileName.zx0")
    return result
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun compressDoynax(
    rootDirectory: String,
    tmpfileName: String,
    thresholdSize: Int,
    fileFlags: MutableSet<FileEntryFlags>
): UByteArray? {
    val errno =
        system("${rootDirectory}${toolsdir}lz -o ${tmpfileName}.lz $tmpfileName")
    if (errno != 0) println("lz command failed")
    val doynaxCompressedFile =
        loadFile("$tmpfileName.lz") ?: throw IllegalStateException("Failed to load lz compressed hunk")

    val result = if (doynaxCompressedFile.size < thresholdSize) {
        removeAllCompressionFlags(fileFlags)
        fileFlags.add(FileEntryFlags.DOYNAX)
        doynaxCompressedFile
    } else {
        null
    }
    unlink("$tmpfileName.lz")
    return result
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun createDelta8EncodedData(data: UByteArray): UByteArray {
    val tmpdata = UByteArray(data.size)
    var prior: UByte = 0U
    for (i in tmpdata.indices) {
        val old = data[i]
        tmpdata[i] = (old - prior).toUByte()
        prior = old
    }
    return tmpdata
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun parseLayoutLine(
    line: String,
    rootDirectory: String,
    fastCompression: Boolean = false
): List<FileEntry> {
    val lineParser = ArgParser("layoutfile")
    val filename by lineParser.argument(ArgType.String, "filename", description = "File to incorporate")
    val targetNameOption by lineParser.option(
        ArgType.String,
        "target",
        "n",
        "Target filename in directory table"
    )
    val lz4Option by lineParser.option(ArgType.Boolean, "lz4", "lz4", "Compress with LZ4")
    val zx0Option by lineParser.option(ArgType.Boolean, "zx0", "zx0", "Compress with ZX0")
    val zstdOption by lineParser.option(ArgType.Boolean, "zstandard", "zstd", "Compress with ZStandard")
    val doynaxOption by lineParser.option(ArgType.Boolean, "doynax", "doy", "Compress with Doynax")
    val bestCompressionOption by lineParser.option(ArgType.Boolean, "best", "bc", "Pick best compression")
    val delta8Option by lineParser.option(ArgType.Boolean, "delta8", "d8", "Delta byte data preprocessing")
    val chipmemOption by lineParser.option(ArgType.Boolean, "chipmem", "cm", "Decrunch to chipmem")
    val hunksOption by lineParser.option(
        ArgType.Boolean,
        "hunks",
        "dos",
        "Loadable DOS hunk (will be split)"
    )
    lineParser.parse(line.split(" ").toTypedArray())
    val rawFile = loadFile(rootDirectory + filename) ?: throw IllegalStateException("File not found")
    val tableEntryName = if (targetNameOption != null) targetNameOption!! else filename.substringAfterLast("/")

    val fileFlags = HashSet<FileEntryFlags>()
    if (doynaxOption == true) {
        fileFlags.add(FileEntryFlags.DOYNAX)
    }
    if (lz4Option == true) {
        fileFlags.add(FileEntryFlags.LZ4)
    }
    if (zx0Option == true) {
        fileFlags.add(FileEntryFlags.ZX0)
    }
    if (zstdOption == true) {
        fileFlags.add(FileEntryFlags.ZSTD)
    }
    if (bestCompressionOption == true) {
        fileFlags.add(FileEntryFlags.BEST_COMPRESSION)
    }
    if (fastCompression) {
        fileFlags.add(FileEntryFlags.FAST)
    }

    val result = if (hunksOption == true) {
        createEntriesForHunkFile(rawFile, fileFlags, rootDirectory, tableEntryName)
    } else {
        fileFlags.add(FileEntryFlags.DATAFILE)
        if (chipmemOption == true) {
            fileFlags.add(FileEntryFlags.CHIPMEM)
        }
        if (delta8Option == true) {
            fileFlags.add(FileEntryFlags.DELTA8)
        }
        val compressedFile = compressFile(tableEntryName, fileFlags, rootDirectory, rawFile)
        val fileEntry = FileEntry(compressedFile ?: rawFile, tableEntryName, fileFlags, rawFile.size, 0)
        arrayListOf(fileEntry)
    }
    println("$tableEntryName processed (${result.sumOf { it.data.size } / 1024} KB diskspace)")
    return result
}

@OptIn(ExperimentalUnsignedTypes::class)
private fun createEntriesForHunkFile(
    rawFile: UByteArray,
    fileFlags: HashSet<FileEntryFlags>,
    rootDirectory: String,
    tableEntryName: String
): ArrayList<FileEntry> {
    if (rawFile.readLong(0) != HUNK_HEADER) throw IllegalStateException("Not a DOS file")
    val numHunks = rawFile.readLong(8).toInt()
    val firstHunk = rawFile.readLong(12).toInt()
    val lastHunk = rawFile.readLong(16).toInt()
    val hunkSizes = UIntArray(lastHunk - firstHunk + 1) { rawFile.readLong(20 + it * 4) }
    var hunkOffset = 20 + numHunks * 4

    var diskoffset = 0
    val filetable = ArrayList<FileEntry>()
    for (hunkNum in 0 until numHunks) {
        val hunkFlags = HashSet(fileFlags)
        if (hunkSizes[hunkNum] shr 30 == MEM_CHIP) {
            hunkFlags.add(FileEntryFlags.CHIPMEM)
        }
        val memorysize = (hunkSizes[hunkNum] and 0xcfffffffU).toInt() * 4
        when (rawFile.readLong(hunkOffset)) {
            HUNK_CODE -> {
                hunkFlags.add(FileEntryFlags.CODE_HUNK)
                hunkOffset += 4
                val hunkSize = rawFile.readLong(hunkOffset).toInt() * 4
                hunkOffset += 4
                val hunkData = rawFile.copyOfRange(hunkOffset, hunkOffset + hunkSize)
                hunkOffset += hunkSize
                //println("Compressing hunk $hunkNum/$numHunks of $tableEntryName")
                val compressedFile = compressFile(tableEntryName, hunkFlags, rootDirectory, hunkData)
                val codeHunkEntry = FileEntry(
                    compressedFile ?: hunkData, tableEntryName,
                    hunkFlags, memorysize,
                    diskoffset,
                    hunkNum,
                    numHunks
                )
                diskoffset += (codeHunkEntry.data.size + 1) and 0x7ffffffe
                filetable.add(codeHunkEntry)
            }

            HUNK_DATA -> {
                hunkFlags.add(FileEntryFlags.DATA_HUNK)
                hunkOffset += 4
                val hunkSize = rawFile.readLong(hunkOffset).toInt() * 4
                hunkOffset += 4
                val hunkData = rawFile.copyOfRange(hunkOffset, hunkOffset + hunkSize)
                hunkOffset += hunkSize
                //println("Compressing hunk $hunkNum/$numHunks of $tableEntryName")
                val compressedFile = compressFile(tableEntryName, hunkFlags, rootDirectory, hunkData)
                val dataHunkEntry = FileEntry(
                    compressedFile ?: hunkData, tableEntryName,
                    hunkFlags, memorysize,
                    diskoffset,
                    hunkNum,
                    numHunks
                )
                diskoffset += (dataHunkEntry.data.size + 1) and 0x7ffffffe
                filetable.add(dataHunkEntry)
            }

            HUNK_BSS -> {
                hunkFlags.add(FileEntryFlags.BSS_HUNK)
                hunkOffset += 4
                val hunkSize = rawFile.readLong(hunkOffset).toInt() * 4
                if (hunkSize != memorysize) throw IllegalStateException("BSS memory size does not match!")
                hunkOffset += 4
                val bssHunkEntry =
                    FileEntry(UByteArray(0), tableEntryName, hunkFlags, memorysize, 0, hunkNum, numHunks)
                filetable.add(bssHunkEntry)
            }

            else -> throw IllegalStateException("Unknown hunk " + rawFile.readLong(hunkOffset) + " at offset $hunkOffset")
        }
        var done = false
        do {
            when (rawFile.readLong(hunkOffset)) {
                HUNK_RELOC32 -> {
                    val relocFlags = HashSet<FileEntryFlags>()
                    relocFlags.add(FileEntryFlags.RELOC_HUNK)
                    hunkOffset += 4
                    val newRelocArray = ArrayList<Int>()
                    do {
                        val numOffsets = rawFile.readLong(hunkOffset).toInt()
                        newRelocArray.add(numOffsets)
                        hunkOffset += 4
                        if (numOffsets == 0) {
                            break
                        }
                        newRelocArray.add(rawFile.readLong(hunkOffset).toInt())
                        hunkOffset += 4
                        val newHunkRelocsArray = ArrayList<Int>()
                        for (i in 0 until numOffsets) {
                            val relocOffset = rawFile.readLong(hunkOffset).toInt()
                            if ((relocOffset and 1) == 1) {
                                throw IllegalStateException("Odd reloc")
                            }
                            if (relocOffset >= 128 * 1024) {
                                throw IllegalStateException("Reloc too big")
                            }
                            newHunkRelocsArray.add(relocOffset / 2)
                            hunkOffset += 4
                        }
                        newHunkRelocsArray.sort()
                        newRelocArray.addAll(newHunkRelocsArray)
                    } while (true)
                    val hunkReloc = UByteArray(newRelocArray.size * 2)
                    for (i in newRelocArray.indices) {
                        hunkReloc.writeWord(i * 2, newRelocArray[i].toUInt())
                    }
                    //println("Relocation Hunk " + hunkReloc.size)
                    val relocHunkEntry =
                        FileEntry(hunkReloc, tableEntryName, relocFlags, 0, diskoffset, hunkNum, numHunks)
                    filetable.add(relocHunkEntry)
                    diskoffset += hunkReloc.size
                }

                HUNK_END -> {
                    hunkOffset += 4
                    done = true
                }

                else -> throw IllegalStateException("Unknown additional hunk " + rawFile.readLong(hunkOffset) + " at offset $hunkOffset")
            }
        } while (!done)
    }
    return filetable
}