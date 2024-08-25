// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {console} from "forge-std/console.sol";

contract ShareMarketPlaceTest is BaseTest {
    function testBuySharesFromMarketPlace__RevertsIfTheListingIsZeroOrDoesNotExist() public {
        address userOne = makeAddr("userOne");

        uint256 nonExistentListing = 1;

        vm.startPrank(userOne);
        vm.expectRevert(Errors.Edjuk8__ListingDoesNotExist.selector);
        shareMarketPlace.buyShares(nonExistentListing);

        nonExistentListing = 0;
        vm.expectRevert(Errors.Edjuk8__ListingDoesNotExist.selector);
        shareMarketPlace.buyShares(nonExistentListing);
        vm.stopPrank();
    }

    function testBuySharesFromMarketPlace__RevertsIfTheBuyerIsTheLister() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userOne);

        vm.startPrank(userOne);
        uint256 latestListingId = shareMarketPlace.shareListings();

        vm.expectRevert(Errors.Edjuk8__CantBuyYourOwnShares.selector);
        shareMarketPlace.buyShares(latestListingId);
        vm.stopPrank();
    }

    function testBuySharesFromMarketPlace__RevertsIfTheListingHasBeenCanceled() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userOne);
        (,,, uint256 userOneActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);
        _cancelShareListing(userOneActiveListing, userOne);

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__ListingNotAvailableAnymore.selector);
        shareMarketPlace.buyShares(userOneActiveListing);
        vm.stopPrank();
    }

    function testBuySharesFromMarketPlace__RevertsIfTheListingHasBeenPurchased() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userOne);
        (,,, uint256 userOneActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);
        _buyShares(userOneActiveListing, makeAddr("User Guy"));

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__ListingNotAvailableAnymore.selector);
        shareMarketPlace.buyShares(userOneActiveListing);
        vm.stopPrank();
    }

    function testBuySharesFromMarketPlace__RevertsIfTheUserHasInsufficientApprovalOrBalance() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userOne);
        (,,, uint256 userOneActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        // edjuk8Token.approve(address(shareMarketPlace), priceToSell);
        _mintEdjuk8Tokens(priceToSell, userTwo);

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__InsufficientBalanceOrAllowanceForListing.selector);
        shareMarketPlace.buyShares(userOneActiveListing);
        vm.stopPrank();
    }

    function testBuySharesFromMarketPlace__TransfersTheTokensToTheSellerAndUpdatesPurchased() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userOne);
        (,,, uint256 userOneActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        _approveEdjuk8Token(address(shareMarketPlace), priceToSell, userTwo);
        _mintEdjuk8Tokens(priceToSell, userTwo);

        uint256 userOneBalBeforeShareSold = edjuk8Token.balanceOf(userOne);

        vm.startPrank(userTwo);
        shareMarketPlace.buyShares(userOneActiveListing);
        vm.stopPrank();

        uint256 userOneBalAfterShareSold = edjuk8Token.balanceOf(userOne);
        address purchased = shareMarketPlace.getShareListingById(userOneActiveListing).purchased;

        assertEq(userOneBalAfterShareSold, userOneBalBeforeShareSold + priceToSell);
        assertEq(purchased, userTwo);
    }

    function testBuySharesFromMarketPlace__UpdatesTheBuyerAndSellerShareDetails() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userThree);
        (,,, uint256 userThreeActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        _approveEdjuk8Token(address(shareMarketPlace), priceToSell, userTwo);
        _mintEdjuk8Tokens(priceToSell, userTwo);

        vm.startPrank(userTwo);
        shareMarketPlace.buyShares(userThreeActiveListing);
        vm.stopPrank();

        (bool user2isShareHolder, uint256 user2SharesAmount,,) =
            courseHandler.getUserCourseShareDetails(courseIdOne, userTwo);

        (bool user3isShareHolder, uint256 user3SharesAmount, uint256 sharesLockedForSale, uint256 user3ActiveListing) =
            courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        uint256 userTwoOwnedCourses = courseHandler.getUserOwnedCourses(userTwo).length;

        assertEq(user2SharesAmount, sharesToSell + 15e4);
        assertEq(user2isShareHolder, true);
        assertEq(userTwoOwnedCourses, 1);

        assertEq(user3isShareHolder, false);
        assertEq(user3SharesAmount, 0);
        assertEq(sharesLockedForSale, 0);
        assertEq(user3ActiveListing, 0);
    }

    ////////// Cancel Share Listing Test //////////

    function testCancelShareListingFromMarketPlace__RevertsIfTheListingIdDoesNotExistOrIsZero() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userThree);
        // (,,, uint256 userThreeActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        vm.startPrank(userThree);
        uint256 nonExistinetListing = 100;

        vm.expectRevert(Errors.Edjuk8__ListingDoesNotExist.selector);
        shareMarketPlace.canceShareListing(nonExistinetListing);

        vm.expectRevert(Errors.Edjuk8__ListingDoesNotExist.selector);
        shareMarketPlace.canceShareListing(0);
        vm.stopPrank();
    }

    function testCancelShareListingFromMarketPlace__RevertsIfTheListingSellerIsNottheCaller() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userThree);
        (,,, uint256 userThreeActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__InvalidCaller.selector);
        shareMarketPlace.canceShareListing(userThreeActiveListing);
        vm.stopPrank();
    }

    function testCancelShareListingFromMarketPlace__RevertsIfTheListingIsAllreadyCanceledOrPurchased() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userThree);
        (,,, uint256 userThreeActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        // _buyShares(userThreeActiveListing, userOne);
        _cancelShareListing(userThreeActiveListing, userThree);

        vm.startPrank(userThree);
        vm.expectRevert(Errors.Edjuk8__ListingNotAvailableAnymore.selector);
        shareMarketPlace.canceShareListing(userThreeActiveListing);
        vm.stopPrank();
    }

    function testCancelShareListingFromMarketPlace__UpdatesTheBuyerAndSellerShareDetails() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15, user3 -> 20, user1 -> 65
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        _sellShare(courseIdOne, sharesToSell, priceToSell, userThree);
        (,,, uint256 userThreeActiveListing) = courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        vm.startPrank(userThree);
        shareMarketPlace.canceShareListing(userThreeActiveListing);
        vm.stopPrank();

        (bool user3isShareHolder, uint256 user3SharesAmount, uint256 sharesLockedForSale, uint256 user3ActiveListing) =
            courseHandler.getUserCourseShareDetails(courseIdOne, userThree);

        uint256 userThreeOwnedCourses = courseHandler.getUserOwnedCourses(userThree).length;

        assertEq(user3isShareHolder, true);
        assertEq(user3SharesAmount, sharesToSell);
        assertEq(sharesLockedForSale, 0);
        assertEq(user3ActiveListing, 0);
        assertEq(userThreeOwnedCourses, 1);
    }

    //     courseHandler.shareUpdate(listing.seller, listing.seller, listing.courseId, listing.shareAmount);
    // }
}
