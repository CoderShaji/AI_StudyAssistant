plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "com.example.app"
    compileSdk = 34
    ndkVersion = "29.0.13846066"
    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    // Correct way to set NDK version
    

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}



