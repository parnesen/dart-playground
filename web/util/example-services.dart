
import 'services.dart';

class ExampleService {
    
    static ExampleService instance() => 
            services.get(ExampleService, () => new ExampleService._create());
    
    ExampleService._create();
    
    String toString() => "Example Service";
}