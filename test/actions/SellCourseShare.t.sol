// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {console} from "forge-std/console.sol";

contract SellCourseShareTest is BaseTest {
    function testSellCourseShare__RevertsIfCourseDoesNotExist() public {
        address userOne = makeAddr("userOne");

        uint256 nonExistentCourseId = 1;
        uint256 sharesToSell = 50e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        // _createCourse(userOne);

        Types.SellShare memory params =
            Types.SellShare({courseId: nonExistentCourseId, sharesAmount: sharesToSell, price: priceToSell});

        vm.startPrank(userOne);
        vm.expectRevert("Non Existent Course");
        courseHandler.sellCourseShare(params);
        vm.stopPrank();
    }

    function testSellCourseShare__RevertsIfOwnerTriesToReduceShareToBeLessThanMinimumHeMustHold() public {
        address userOne = makeAddr("userOne");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 80e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesToSell, price: priceToSell});

        vm.startPrank(userOne);
        vm.expectRevert(Errors.Edjuk9__OwnerCantHaveLessThanMinimumPercentShare.selector);
        courseHandler.sellCourseShare(params);
        vm.stopPrank();
    }

    function testSellCourseShare__RevertsIfUserIsNotAShareHolder() public {
        address userOne = makeAddr("userOne");
        address nonShareHolder = makeAddr("nonShareHolder");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 80e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesToSell, price: priceToSell});

        vm.startPrank(nonShareHolder);
        vm.expectRevert(Errors.Edjuk8__NotAShareHolder.selector);
        courseHandler.sellCourseShare(params);
        vm.stopPrank();
    }

    function testSellCourseShare__RevertsIfSharesAmountIsZeroOrLessThanShareUserHas() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");
        uint256 courseIdOne = 1;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // basically gives user two and three 15 and 20 shares respectively and returns the current listing id count
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        uint256 sharesAboveWhatUserTwoHas = 30e4;
        uint256 priceToSell = 10e18;

        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesAboveWhatUserTwoHas, price: priceToSell});

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__InsufficentSharesBalance.selector);
        courseHandler.sellCourseShare(params);

        // // updates the shares amount to sell to zero and check for revert
        params.sharesAmount = 0;
        vm.expectRevert(Errors.Edjuk8__SharesToSellCannotBeZero.selector);
        courseHandler.sellCourseShare(params);
        vm.stopPrank();
    }

    function testSellCourseShare__UpdatesTheSharesLockedAndReducesTheUserShare() public {
        address userOne = makeAddr("userOne");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        (, uint256 sharesAmountBefore,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        vm.startPrank(userOne);
        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesToSell, price: priceToSell});
        courseHandler.sellCourseShare(params);
        vm.stopPrank();

        (bool isShareHolder, uint256 sharesAmount, uint256 sharesLockedForSale,) =
            courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        assertEq(sharesLockedForSale, sharesToSell);
        assertEq(sharesAmount, sharesAmountBefore - sharesToSell);
        assertEq(isShareHolder, true);
    }

    function testSellCourseShare__OnShareMarketPlace__CanOnlyBeCalledByCourseHandler() public {
        address userOne = makeAddr("userOne");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 20e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        vm.startPrank(userOne);

        vm.expectRevert("! CourseHandler");
        shareMarketPlace.sellShares(userOne, sharesToSell, courseIdOne, priceToSell);
        vm.stopPrank();
    }

    function testSellCourseShare__OnShareMarketPlace__RevertsWhenTheUserAlreadyHasACourseShareOnSale() public {
        address userOne = makeAddr("userOne");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        vm.startPrank(userOne);
        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesToSell, price: priceToSell});
        courseHandler.sellCourseShare(params);

        // new sale share amount
        params.sharesAmount = 1e4;

        // sell more shares of a course Id on the market place should revert, one course share sale at a time
        vm.expectRevert(Errors.Edjuk8__UserCourseSharesAlreadyOnSale.selector);
        courseHandler.sellCourseShare(params);

        vm.stopPrank();
    }

    function testSellCourseShare__OnShareMarketPlace__UpdatesTheSaleListing() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToSell = 10e4;
        uint256 priceToSell = 10e18; // price in edjuk-8 token

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        vm.startPrank(userOne);
        Types.SellShare memory params =
            Types.SellShare({courseId: courseIdOne, sharesAmount: sharesToSell, price: priceToSell});
        courseHandler.sellCourseShare(params);
        vm.stopPrank();

        Types.ShareListing memory listing = shareMarketPlace.getShareListingById(shareMarketPlace.shareListings());

        (,,, uint256 userActiveListingId) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        assertEq(listing.seller, userOne);
        assertEq(listing.courseId, courseIdOne);
        assertEq(listing.shareAmount, sharesToSell);
        assertEq(listing.ID, 3);
        assertEq(userActiveListingId, 3);
    }

    // Look out
    // userCourseShares
    // isShareHolder
    // user ownedCourses

    /////////////////////////////////////////////////////////////////////
    ///////////////////////// With Sig Test /////////////////////////////
    /////////////////////////////////////////////////////////////////////

    // struct RegisterWithSig {
    //     address user;
    //     string username;
    //     uint256 deadline;
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    // }

    // function testRegisterUserWithSig__UpdatesTheUserDetailsAndUserNameTaken() public {
    //     (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
    //     // address userTwo = makeAddr("userTwo");

    //     uint256 deadline = block.timestamp + oneMinute;
    //     uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

    //     vm.startPrank(userOne);

    //     Types.RegisterWithSig memory params =
    //         Types.RegisterWithSig({user: userOne, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

    //     bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
    //     bytes32 digest = courseHandler.getTypedDataHash(structHash);

    //     (params.v, params.r, params.s) = vm.sign(userOneKey, digest);

    //     courseHandler.registerUserWithSig(params);
    //     vm.stopPrank();

    //     Types.User memory user = courseHandler.getUserDetails(userOne);
    //     assertEq(user.username, usernameOne);
    //     assertEq(user.author, true);
    // }

    function _prepareUserTwoAndThreeWithShares(address userOne, address userTwo, address userThree, uint256 courseId)
        private
        returns (uint256)
    {
        // user one sells 15 shares and user two buys
        // user one sells 20 shares and user three buys

        uint256 sharesToSellUserTwo = 15e4;
        uint256 sharesToSellUserThree = 20e4;
        uint256 priceToSellShares = 5e18;

        uint256 listingId = 1;

        _sellShare(courseId, sharesToSellUserTwo, priceToSellShares, userOne);
        _buyShares(listingId, userTwo);

        listingId++;

        _sellShare(courseId, sharesToSellUserThree, priceToSellShares, userOne);
        _buyShares(listingId, userThree);

        return listingId;
    }
}
