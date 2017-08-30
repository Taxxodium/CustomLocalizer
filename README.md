# CustomLocalizer
Small macOS app that can help out with localizing an Xcode project

## Description

This app has several features, including the following:

- detect duplicated keys from .strings files
- extract all objective C strings from a project (must have at least an en.lproj)
- localize using a CSV file (more on this below)

## Localization from a CSV file

* Prepare your CSV file

The headers for the CSV file need to have all the language code you want to translate. It's very important that the first column is en (for english strings).
Also for each language code you must have an .lproj folder

example:

en,es,nl
This is a test,Esto es una prueba,Dit is een test

* A note about UI strings

The app has a checkbox to translate only UI strings (ie strings that are not in the Localizable.strings file).

* Localize

Once you've localized the strings, these will appear at the top of the Localizable.strings file.
For UI, the original text will just be replaced with the new strings.

*It's very important you have at least an en.lproj folder*
