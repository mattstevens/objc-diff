# objc-diff

Generates a text, XML, or HTML report of the API differences between two versions of an Objective-C library. It assists library authors with creating a diff report for their users and verifying that no unexpected API changes have been made.

## Status

Beta. The tool has been tested against the system frameworks and a number of third-party libraries, but I'd like to open it to feedback and additional testing before considering the command line interface and XML format stable.

## Usage

    objc-diff [--old <path to old API>] --new <path to new API> [options]

    API paths may be specified as a path to a framework, a path to a single
    header, or a path to a directory of headers.

    Options:
      --help             Show this help message and exit
      --title            Title of the generated report
      --text             Write a text report to standard output (the default)
      --xml              Write an XML report to standard output
      --html <directory> Write an HTML report to the specified directory
      --sdk <name>       Use the specified SDK
      --old <path>       Path to the old API
      --new <path>       Path to the new API
      --args <args>      Compiler arguments for both API versions
      --oldargs <args>   Compiler arguments for the old API version
      --newargs <args>   Compiler arguments for the new API version
      --version          Show the version and exit

See the [man page](http://codeworkshop.net/objc-diff/man-page) for expanded usage information.