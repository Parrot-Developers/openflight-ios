import XCTest
import CoreLocation
import Hamcrest

class ObstacleAvoidanceMonitorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHamcrest() {
        var optional: Int = 1 + 1
        assertThat(optional, present())
    }

}
