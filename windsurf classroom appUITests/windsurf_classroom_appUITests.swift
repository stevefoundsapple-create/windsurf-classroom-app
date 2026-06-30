import XCTest

final class LoginViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITesting", "-UITestingRole none"]
        app.launch()
    }

    func test_loginView_showsAllElements() {
        let emailField = app.textFields["login-email-field"]
        let passwordField = app.secureTextFields["login-password-field"]
        let signInButton = app.buttons["login-sign-in-button"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2))
        XCTAssertTrue(signInButton.waitForExistence(timeout: 2))
        XCTAssertTrue(signInButton.isEnabled == false)
    }

    func test_loginView_signInButton_enabledWhenFieldsFilled() {
        let emailField = app.textFields["login-email-field"]
        emailField.tap()
        emailField.typeText("teacher@example.com")

        let passwordField = app.secureTextFields["login-password-field"]
        passwordField.tap()
        passwordField.typeText("password")

        let signInButton = app.buttons["login-sign-in-button"]
        XCTAssertTrue(signInButton.isEnabled)
    }

    func test_loginView_navigationTitleShows() {
        let title = app.staticTexts["Classroom Behavior"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))

        let subtitle = app.staticTexts["Track behavior in real-time"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: 1))
    }
}

final class TeacherFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITesting", "-UITestingRole teacher", "-UITestingDataState populated"]
        app.launch()
    }

    func test_dashboard_showsStudentCards() {
        let studentCard = app.otherElements["student-card-Alice"]
        XCTAssertTrue(studentCard.waitForExistence(timeout: 3))

        XCTAssertTrue(app.otherElements["student-card-Bob"].exists)
        XCTAssertTrue(app.otherElements["student-card-Charlie"].exists)
    }

    func test_dashboard_showsToolbarButtons() {
        XCTAssertTrue(app.buttons["dashboard-add-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["dashboard-qr-button"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["dashboard-menu-button"].waitForExistence(timeout: 1))
    }

    func test_dashboard_emptyState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole teacher", "-UITestingDataState empty"]
        app.launch()

        let emptyState = app.otherElements["dashboard-empty"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["No Students Yet"].exists)
    }

    func test_dashboard_errorState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole teacher", "-UITestingDataState error"]
        app.launch()

        let errorState = app.otherElements["dashboard-error"]
        XCTAssertTrue(errorState.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["error-retry-button"].exists)
    }

    func test_dashboard_tapStudentCard() {
        let studentCard = app.otherElements["student-card-Alice"]
        XCTAssertTrue(studentCard.waitForExistence(timeout: 3))
        studentCard.tap()

        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 2))
    }
}

final class ParentFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITesting", "-UITestingRole parent", "-UITestingDataState populated"]
        app.launch()
    }

    func test_parentHome_showsTabView() {
        let tabView = app.otherElements["parent-tab-view"]
        XCTAssertTrue(tabView.waitForExistence(timeout: 3))
    }

    func test_parentHome_tabNavigation() {
        let reportsTab = app.otherElements["parent-tab-reports"]
        XCTAssertTrue(reportsTab.waitForExistence(timeout: 3))
        reportsTab.tap()

        let settingsTab = app.otherElements["parent-tab-settings"]
        settingsTab.tap()
    }

    func test_parentFeed_showsContent() {
        let childName = app.staticTexts["Alice"]
        XCTAssertTrue(childName.waitForExistence(timeout: 3))
    }

    func test_parentSettings_showsButtons() {
        let settingsTab = app.otherElements["parent-tab-settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3))
        settingsTab.tap()

        let logOutButton = app.buttons["settings-log-out-button"]
        XCTAssertTrue(logOutButton.waitForExistence(timeout: 2))
    }

    func test_parentSettings_emptyState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole parent", "-UITestingDataState empty"]
        app.launch()

        let settingsTab = app.otherElements["parent-tab-settings"]
        settingsTab.tap()

        let linkChildButton = app.buttons["settings-link-child-button"]
        XCTAssertTrue(linkChildButton.waitForExistence(timeout: 3))
    }

    func test_parentFeed_errorState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole parent", "-UITestingDataState error"]
        app.launch()

        let errorState = app.otherElements["parent-feed-error"]
        XCTAssertTrue(errorState.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["error-retry-button"].exists)
    }

    func test_parentFeed_emptyState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole parent", "-UITestingDataState empty"]
        app.launch()

        let emptyState = app.otherElements["parent-feed-empty"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3))
    }
}

final class StudentFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITesting", "-UITestingRole student", "-UITestingDataState populated"]
        app.launch()
    }

    func test_studentHome_showsPointTotal() {
        let pointTotal = app.otherElements["student-point-total"]
        XCTAssertTrue(pointTotal.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Your Points"].exists)
    }

    func test_studentHome_showsEventFeed() {
        let contentView = app.otherElements["student-content"]
        XCTAssertTrue(contentView.waitForExistence(timeout: 3))
    }

    func test_studentHome_emptyState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole student", "-UITestingDataState empty"]
        app.launch()

        let emptyState = app.otherElements["student-empty"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["No Events Yet"].exists)
    }

    func test_studentHome_errorState() {
        app.terminate()
        app.launchArguments = ["-UITesting", "-UITestingRole student", "-UITestingDataState error"]
        app.launch()

        let errorState = app.otherElements["student-error"]
        XCTAssertTrue(errorState.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["error-retry-button"].exists)
    }
}

final class NavigationUITests: XCTestCase {
    let app = XCUIApplication()

    func test_login_teacher_redirectsToDashboard() {
        app.launchArguments = ["-UITesting", "-UITestingRole teacher"]
        app.launch()

        let dashboard = app.otherElements["student-card-Alice"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 3))
    }

    func test_login_parent_redirectsToParentHome() {
        app.launchArguments = ["-UITesting", "-UITestingRole parent"]
        app.launch()

        let tabView = app.otherElements["parent-tab-view"]
        XCTAssertTrue(tabView.waitForExistence(timeout: 3))
    }

    func test_login_student_redirectsToStudentHome() {
        app.launchArguments = ["-UITesting", "-UITestingRole student"]
        app.launch()

        let pointTotal = app.otherElements["student-point-total"]
        XCTAssertTrue(pointTotal.waitForExistence(timeout: 3))
    }

    func test_login_showsForNoneRole() {
        app.launchArguments = ["-UITesting", "-UITestingRole none"]
        app.launch()

        let emailField = app.textFields["login-email-field"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
    }
}

final class LaunchTests: XCTestCase {
    let app = XCUIApplication()

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
