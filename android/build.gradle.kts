group = "com.tapresearch.tapresearch_flutter_plugin"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
        maven("https://artifactory.tools.tapresearch.io/artifactory/tapresearch-android-sdk/")
        mavenLocal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://artifactory.tools.tapresearch.io/artifactory/tapresearch-android-sdk/")
        mavenLocal()
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.tapresearch.tapresearch_flutter_plugin"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")

    // required by tap research sdk
    // implementation("com.tapresearch:tapsdk:3.8.0--beta04-local")
    implementation("com.tapresearch:tapsdk:3.7.3--rc2")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.5.0")
    implementation("androidx.lifecycle:lifecycle-process:2.6.1")
    implementation("com.google.android.gms:play-services-ads-identifier:18.1.0")
    implementation("androidx.core:core-ktx:1.10.1")
    implementation("com.google.android.gms:play-services-appset:16.1.0")
}
