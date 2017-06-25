0.4.0

* Fixed class extensions being excluded
* Changed the way categories are handled. Categories and class extensions for classes within the same module
  are no longer reported. Their children are still reported, but the extensions that the category or class
  extension make to the class are now reported as modifications of the class (e.g., extending the set of
  protocols that a class conforms to). This better reflects the effect that the addition or removal of a
  category has on the API.

  Categories on classes from other modules are still reported.

0.3.0 (2017-06-14)

* Updated Clang to 4.0.0
* Added support for class properties.
* Added support for replacements in availability and deprecated attributes.
* Added support for "soft deprecations" via categories containing "Deprecated" in their name.
* Added support for comparing platform SDKs (e.g. the iOS SDK in Xcode). All frameworks in the SDK are
  compared, with a few exceptions that cannot currently be parsed:

  - IOKit.framework
  - Kernel.framework
  - Tk.framework

  The contents of /usr/include are also not currently parsed, as some of these headers must be included in
  a specific order.

  SDK comparisions may be performed on a whole-SDK basis or for specific frameworks within the SDK.

0.2.0 (2015-11-19)

* Updated Clang to 3.7.0.
* Added support for nullability annotations.
* A change to the inline status of a function is no longer reported as an addition and a removal of that function.
* Relocation of a static variable is no longer reported as an addition and a removal of that variable.

0.1.0 (2014-06-18)

* Initial release.
