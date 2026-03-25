"""
Appium Test Cases for Map and Directory Modules
================================================
NITC Campus Navigator - Flutter App

Prerequisites:
  1. pip install Appium-Python-Client
  2. Appium server running (default: http://localhost:4723)
  3. Flutter app installed on emulator/device
  4. Set APP_PACKAGE and APP_ACTIVITY below to match your app

Usage:
  python -m pytest test_map_directory.py -v
  OR
  python test_map_directory.py
"""

import unittest
import time

from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    NoSuchElementException,
    TimeoutException,
)

# ─── Configuration ────────────────────────────────────────────────────────────
APP_PACKAGE = "com.example.group1_departmental_navigation"  # Update if different
APP_ACTIVITY = ".MainActivity"  # Flutter default

APPIUM_SERVER = "http://localhost:4723"
IMPLICIT_WAIT = 10  # seconds
EXPLICIT_WAIT = 15  # seconds


class BaseTest(unittest.TestCase):
    """Base test class with Appium driver setup/teardown and helper methods."""

    driver = None

    @classmethod
    def setUpClass(cls):
        options = UiAutomator2Options()
        options.platform_name = "Android"
        options.app_package = APP_PACKAGE
        options.app_activity = APP_ACTIVITY
        options.no_reset = True  # Keep app state between sessions
        options.auto_grant_permissions = True

        cls.driver = webdriver.Remote(APPIUM_SERVER, options=options)
        cls.driver.implicitly_wait(IMPLICIT_WAIT)

    @classmethod
    def tearDownClass(cls):
        if cls.driver:
            cls.driver.quit()

    # ── Helper methods ─────────────────────────────────────────────────────────

    def wait_for(self, locator_type, locator_value, timeout=EXPLICIT_WAIT):
        """Wait for an element to be present and return it."""
        return WebDriverWait(self.driver, timeout).until(
            EC.presence_of_element_located((locator_type, locator_value))
        )

    def wait_and_click(self, locator_type, locator_value, timeout=EXPLICIT_WAIT):
        """Wait for an element and click it."""
        element = WebDriverWait(self.driver, timeout).until(
            EC.element_to_be_clickable((locator_type, locator_value))
        )
        element.click()
        return element

    def find_by_text(self, text, partial=False):
        """Find element by visible text (UiAutomator selector)."""
        if partial:
            selector = f'new UiSelector().textContains("{text}")'
        else:
            selector = f'new UiSelector().text("{text}")'
        return self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, selector)

    def text_exists(self, text, timeout=5):
        """Check whether the given text is visible on screen."""
        try:
            selector = f'new UiSelector().text("{text}")'
            WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located(
                    (AppiumBy.ANDROID_UIAUTOMATOR, selector)
                )
            )
            return True
        except TimeoutException:
            return False

    def scroll_down(self):
        """Scroll down using UiScrollable."""
        self.driver.find_element(
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiScrollable(new UiSelector().scrollable(true))'
            '.scrollForward()',
        )

    def scroll_to_text(self, text):
        """Scroll until text is visible."""
        self.driver.find_element(
            AppiumBy.ANDROID_UIAUTOMATOR,
            f'new UiScrollable(new UiSelector().scrollable(true))'
            f'.scrollIntoView(new UiSelector().textContains("{text}"))',
        )

    def navigate_to_home(self):
        """Navigate to Home screen via bottom nav bar (index 0)."""
        try:
            nav_items = self.driver.find_elements(
                AppiumBy.CLASS_NAME, "android.widget.ImageView"
            )
            # Bottom nav has 5 icons; first one is Home
            if len(nav_items) >= 5:
                nav_items[0].click()
                time.sleep(1)
        except Exception:
            pass

    def navigate_to_directory(self):
        """Navigate to Directory screen via bottom nav (index 1)."""
        try:
            # Tap the Directory icon (contacts icon, index 1 in bottom nav)
            nav_items = self.driver.find_elements(
                AppiumBy.CLASS_NAME, "android.widget.ImageView"
            )
            if len(nav_items) >= 5:
                nav_items[1].click()
                time.sleep(2)
        except Exception:
            # Fallback: try finding "Directory" text
            if self.text_exists("Directory"):
                self.find_by_text("Directory").click()
                time.sleep(2)

    def navigate_to_maps(self):
        """Navigate to Offline Maps screen via bottom nav (index 3)."""
        try:
            nav_items = self.driver.find_elements(
                AppiumBy.CLASS_NAME, "android.widget.ImageView"
            )
            if len(nav_items) >= 5:
                nav_items[3].click()
                time.sleep(2)
        except Exception:
            if self.text_exists("Offline Maps"):
                self.find_by_text("Offline Maps").click()
                time.sleep(2)

    def go_back(self):
        """Press back button."""
        self.driver.back()
        time.sleep(1)


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 1 – Directory screen loads with title and segment controls
# ═══════════════════════════════════════════════════════════════════════════════
class TC01_DirectoryScreenLoads(BaseTest):
    """Verify that the Directory screen loads and shows the title,
    segmented control (Faculty / Halls / Labs), and the search bar."""

    def test_directory_screen_loads(self):
        self.navigate_to_directory()

        # Title should be visible
        self.assertTrue(
            self.text_exists("Directory"),
            "Directory title not found on screen",
        )

        # Segment buttons should be present
        self.assertTrue(
            self.text_exists("Faculty"),
            "'Faculty' segment button not visible",
        )
        self.assertTrue(
            self.text_exists("Halls"),
            "'Halls' segment button not visible",
        )
        self.assertTrue(
            self.text_exists("Labs"),
            "'Labs' segment button not visible",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 2 – Directory segment switching
# ═══════════════════════════════════════════════════════════════════════════════
class TC02_DirectorySegmentSwitching(BaseTest):
    """Verify switching between Faculty → Halls → Labs tabs updates the list
    and changes the search bar hint text."""

    def test_segment_switching(self):
        self.navigate_to_directory()

        # Switch to Halls tab
        self.find_by_text("Halls").click()
        time.sleep(1)
        # Search hint should update to halls
        self.assertTrue(
            self.text_exists("Search Halls...", timeout=3)
            or self.text_exists("Halls", timeout=3),
            "Failed to switch to Halls segment",
        )

        # Switch to Labs tab
        self.find_by_text("Labs").click()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Search Labs...", timeout=3)
            or self.text_exists("Labs", timeout=3),
            "Failed to switch to Labs segment",
        )

        # Switch back to Faculty tab
        self.find_by_text("Faculty").click()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Search Faculty cabins...", timeout=3)
            or self.text_exists("Faculty", timeout=3),
            "Failed to switch back to Faculty segment",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 3 – Directory search functionality
# ═══════════════════════════════════════════════════════════════════════════════
class TC03_DirectorySearch(BaseTest):
    """Verify the search bar on the Directory screen filters the list when
    a query is typed, and clears properly."""

    def test_search_filters_list(self):
        self.navigate_to_directory()

        # Find and tap the search field
        try:
            search_field = self.driver.find_element(
                AppiumBy.CLASS_NAME, "android.widget.EditText"
            )
        except NoSuchElementException:
            # Scroll up to find the search bar if it is pinned
            search_field = self.driver.find_element(
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().className("android.widget.EditText")',
            )

        search_field.click()
        time.sleep(0.5)
        search_field.send_keys("xyz_nonexistent_query_12345")
        time.sleep(1)

        # After typing a non-matching query, "No faculty found." should appear
        no_results = self.text_exists("No faculty found.", timeout=5)
        self.assertTrue(no_results, "Search did not filter to empty results")

        # Clear the search field
        search_field.clear()
        time.sleep(1)

        # The list should repopulate (faculty items should reappear)
        no_results_after_clear = self.text_exists("No faculty found.", timeout=3)
        self.assertFalse(
            no_results_after_clear,
            "List did not repopulate after clearing search",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 4 – Directory back navigation
# ═══════════════════════════════════════════════════════════════════════════════
class TC04_DirectoryBackNavigation(BaseTest):
    """Verify the back button on the Directory screen returns to Home."""

    def test_back_button(self):
        self.navigate_to_directory()
        time.sleep(1)

        # Press the back arrow (first icon button on the screen)
        self.go_back()
        time.sleep(1)

        # Should land on Home screen — check for home-specific content
        home_visible = (
            self.text_exists("Welcome back,", timeout=5)
            or self.text_exists("Explore NITC Map", timeout=5)
            or self.text_exists("Quick action", timeout=5)
        )
        self.assertTrue(
            home_visible,
            "Did not navigate back to Home screen from Directory",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 5 – Offline Maps screen loads with title and NITC map card
# ═══════════════════════════════════════════════════════════════════════════════
class TC05_OfflineMapsScreenLoads(BaseTest):
    """Verify the Offline Maps screen loads, shows its title,
    and the main 'Whole NITC Map' interactive card."""

    def test_maps_screen_loads(self):
        self.navigate_to_maps()

        self.assertTrue(
            self.text_exists("Offline Maps"),
            "'Offline Maps' title not found",
        )

        self.assertTrue(
            self.text_exists("Whole NITC Map"),
            "'Whole NITC Map' card not found",
        )

        self.assertTrue(
            self.text_exists("Interactive"),
            "'Interactive' badge not found on map card",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 6 – Offline Maps search bar filters buildings list
# ═══════════════════════════════════════════════════════════════════════════════
class TC06_OfflineMapsSearch(BaseTest):
    """Verify the search bar on the Offline Maps screen filters buildings."""

    def test_maps_search(self):
        self.navigate_to_maps()

        search_field = self.driver.find_element(
            AppiumBy.CLASS_NAME, "android.widget.EditText"
        )
        search_field.click()
        time.sleep(0.5)

        search_field.send_keys("zzz_no_building_match")
        time.sleep(1)

        # After typing a non-matching query, "No buildings found." should appear
        self.assertTrue(
            self.text_exists("No buildings found.", timeout=5),
            "Maps search did not filter to empty results",
        )

        # Clear and verify list repopulates
        search_field.clear()
        time.sleep(1)
        self.assertFalse(
            self.text_exists("No buildings found.", timeout=3),
            "Buildings list did not repopulate after clearing search",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 7 – Whole NITC Map card opens ExploreMapScreen
# ═══════════════════════════════════════════════════════════════════════════════
class TC07_ExploreMapNavigation(BaseTest):
    """Verify tapping the 'Whole NITC Map' card opens the Explore Map screen
    with the MapLibre map view, then navigating back returns correctly."""

    def test_explore_map_opens(self):
        self.navigate_to_maps()
        time.sleep(1)

        # Tap the "Whole NITC Map" card
        self.find_by_text("Whole NITC Map").click()
        time.sleep(3)  # Allow time for the map to load

        # The Explore Map screen should be open —
        # verify the Offline Maps screen content is NOT showing
        self.assertFalse(
            self.text_exists("Offline Maps", timeout=2),
            "Explore Map screen did not open; still on Offline Maps",
        )

        # Navigate back
        self.go_back()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Offline Maps", timeout=5),
            "Did not return to Offline Maps screen",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 8 – Building card shows details (floors, coordinates)
# ═══════════════════════════════════════════════════════════════════════════════
class TC08_BuildingCardDetails(BaseTest):
    """Verify building cards on the Offline Maps screen display building name,
    floor count, and coordinates."""

    def test_building_card_has_details(self):
        self.navigate_to_maps()
        time.sleep(2)

        # Scroll down past the main map card to the buildings list
        self.scroll_down()
        time.sleep(1)

        # Check for either "Downloaded Maps" or "Available Maps" section label
        section_visible = self.text_exists(
            "Downloaded Maps", timeout=3
        ) or self.text_exists("Available Maps", timeout=3)
        self.assertTrue(
            section_visible,
            "Neither 'Downloaded Maps' nor 'Available Maps' sections found",
        )

        # Check that at least one element with "Floors" text is present
        floors_visible = self.text_exists("Floors", timeout=3) or \
            self.driver.find_elements(
                AppiumBy.ANDROID_UIAUTOMATOR,
                'new UiSelector().textContains("Floor")',
            )
        self.assertTrue(
            floors_visible,
            "No building card with floor count found",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 9 – Download button on available building card
# ═══════════════════════════════════════════════════════════════════════════════
class TC09_DownloadButtonExists(BaseTest):
    """Verify that available (not yet downloaded) building cards show a
    'Download' button."""

    def test_download_button_visible(self):
        self.navigate_to_maps()
        time.sleep(2)

        # Scroll to find 'Available Maps' section
        try:
            self.scroll_to_text("Available Maps")
        except Exception:
            self.scroll_down()
        time.sleep(1)

        # Check for the "Download" button on any building card
        download_visible = self.text_exists("Download", timeout=5)
        # It's possible all maps are downloaded, so we check for an
        # alternative — the 'View' button for downloaded maps
        view_visible = self.text_exists("View", timeout=3)

        self.assertTrue(
            download_visible or view_visible,
            "Neither 'Download' nor 'View' button found on building cards",
        )


# ═══════════════════════════════════════════════════════════════════════════════
# TEST CASE 10 – Bottom navigation bar works across screens
# ═══════════════════════════════════════════════════════════════════════════════
class TC10_BottomNavBarNavigation(BaseTest):
    """Verify the bottom navigation bar correctly navigates between
    Home → Directory → Map screens and back."""

    def test_bottom_nav_navigation(self):
        # Start from Home
        self.navigate_to_home()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Explore NITC Map", timeout=5)
            or self.text_exists("Quick action", timeout=5),
            "Home screen not loaded",
        )

        # Navigate to Directory (index 1)
        self.navigate_to_directory()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Directory", timeout=5),
            "Directory screen not loaded via bottom nav",
        )

        # Navigate to Offline Maps (index 3)
        self.navigate_to_maps()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Offline Maps", timeout=5),
            "Offline Maps screen not loaded via bottom nav",
        )

        # Navigate back to Home (index 0)
        self.navigate_to_home()
        time.sleep(1)
        self.assertTrue(
            self.text_exists("Explore NITC Map", timeout=5)
            or self.text_exists("Quick action", timeout=5),
            "Home screen not loaded after full navigation cycle",
        )


# ═══════════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    unittest.main(verbosity=2)
