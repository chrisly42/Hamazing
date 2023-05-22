plugins {
    application
    kotlin("multiplatform") version "1.8.21"
}

repositories {
    mavenCentral()
}

kotlin {
    sourceSets {
        commonMain {
            dependencies {
                implementation("org.jetbrains.kotlinx:kotlinx-cli:0.3.5")
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.0")
            }
        }
    }

    val hostOs = System.getProperty("os.name")
    val isMingwX64 = hostOs.startsWith("Windows")
    val nativeTarget = when {
        hostOs == "Mac OS X" -> macosX64("native")
        hostOs == "Linux" -> linuxX64("native")
        isMingwX64 -> mingwX64("native")
        else -> throw GradleException("Host OS is not supported in Kotlin/Native.")
    }
    val crossTarget = mingwX64("wingw64")

    nativeTarget.apply {
        compilations["main"].enableEndorsedLibs = true
        binaries {
            executable("platosadf") {
                entryPoint = "de.platon42.demoscene.tools.platosadf.main"
            }
            executable("juggler") {
                entryPoint = "de.platon42.demoscene.tools.juggler.main"
            }
        }
    }

    crossTarget.apply {
        compilations["main"].enableEndorsedLibs = true
        binaries {
            executable("platosadf") {
                entryPoint = "de.platon42.demoscene.tools.platosadf.main"
            }
            executable("juggler") {
                entryPoint = "de.platon42.demoscene.tools.juggler.main"
            }
        }
    }

    sourceSets {
        val nativeMain by getting
        val nativeTest by getting
    }
}