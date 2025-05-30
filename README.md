This script recursively executes flutter packages get in the main Flutter project and all locally referenced packages, ensuring dependencies are updated across the entire codebase and its sub-packages. It will also clear PluginManager if you have used `candies_analyzer_plugin`

### Activate flutter_packages_get

 `dart pub global activate flutter_packages_get`

 ### Used

 run `fpg` in your main project