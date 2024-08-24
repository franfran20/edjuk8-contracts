// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IShareMarketPlace} from "./interfaces/IShareMarketPlace.sol";
import {ICourseHandler} from "./interfaces/ICourseHandler.sol";
import {Edjuk8Token} from "./Edjuk8Token.sol";
import {Types} from "./utils/Types.sol";
import {Errors} from "./utils/Errors.sol";

contract ShareMarketPlace is IShareMarketPlace {
    Types.ShareListing[] allListings;
    ICourseHandler courseHandler;
    Edjuk8Token edjuk8Token;

    uint256 public shareListings;

    mapping(address user => mapping(uint256 courseId => bool)) _shareListings;

    modifier onlyCourseHandler() {
        require(msg.sender == address(courseHandler), "! CourseHandler");
        _;
    }

    constructor(address courseHandlerAddress, address edjuk8TokenAddress) {
        courseHandler = ICourseHandler(courseHandlerAddress);
        edjuk8Token = Edjuk8Token(edjuk8TokenAddress);
    }

    function setCourseHandler(address courseHandlerAddress) public {
        courseHandler = ICourseHandler(courseHandlerAddress);
    }

    // only callable by the course handler
    function sellShares(address user, uint256 shareAmount, uint256 courseId, uint256 price)
        external
        onlyCourseHandler
        returns (uint256)
    {
        if (_shareListings[user][courseId]) {
            revert Errors.Edjuk8__UserCourseSharesAlreadyOnSale();
        }

        _shareListings[user][courseId] = true;
        shareListings++;

        allListings.push(
            Types.ShareListing({
                seller: user,
                courseId: courseId,
                shareAmount: shareAmount,
                totalPrice: price,
                courseName: courseHandler.getCourseById(courseId).name,
                courseOwner: courseHandler.getCourseById(courseId).ownerName,
                imageURI: courseHandler.getCourseById(courseId).imageURI,
                valid: true, // to keep track of if a user share wasnt purchased but the dropped by the user
                purchased: address(0),
                ID: shareListings
            })
        );

        emit CourseSharesListed(user, courseId, shareAmount);

        return shareListings;
    }

    function buyShares(uint256 listingId) external payable {
        if (listingId > shareListings || listingId == 0) {
            revert Errors.Edjuk8__ListingDoesNotExist();
        }

        uint256 listingIndex = listingId - 1;
        Types.ShareListing memory listing = allListings[listingIndex];

        if (listing.seller == msg.sender) {
            revert Errors.Edjuk8__CantBuyYourOwnShares();
        }
        if (listing.purchased != address(0) || !listing.valid) {
            revert Errors.Edjuk8__ListingNotAvailableAnymore();
        }
        if (
            edjuk8Token.balanceOf(msg.sender) < listing.totalPrice
                || edjuk8Token.allowance(msg.sender, address(this)) < listing.totalPrice
        ) {
            revert Errors.Edjuk8__InsufficientBalanceOrAllowanceForListing();
        }

        edjuk8Token.transferFrom(msg.sender, listing.seller, listing.totalPrice);

        _shareListings[listing.seller][listing.courseId] = false;
        allListings[listingIndex].purchased = msg.sender;

        courseHandler.shareUpdate(listing.seller, msg.sender, listing.courseId, listing.shareAmount);

        emit SharesPurchased(msg.sender, listingId, listing.courseId, listing.shareAmount);
    }

    // drop a users share sale
    function canceShareListing(uint256 listingId) external {
        if (listingId > shareListings || listingId == 0) {
            revert Errors.Edjuk8__ListingDoesNotExist();
        }

        uint256 listingIndex = listingId - 1;
        Types.ShareListing memory listing = allListings[listingIndex - 1];

        if (msg.sender != listing.seller || msg.sender != address(courseHandler)) {
            revert Errors.Edjuk8__InvalidCaller();
        }

        if (listing.purchased != address(0) || !listing.valid) {
            revert Errors.Edjuk8__ListingNotAvailableAnymore();
        }

        _shareListings[listing.seller][listing.courseId] = false;
        allListings[listingIndex].purchased = address(0);
        allListings[listingIndex].valid = false;

        courseHandler.shareUpdate(listing.seller, listing.seller, listing.courseId, listing.shareAmount);
    }

    // getter functions
    // try8 and and add paginaion to each to fetch by index and stuff
    function getAllShareListings() external view returns (Types.ShareListing[] memory) {
        return allListings;
    }

    function getShareListingById(uint256 listingId) external view returns (Types.ShareListing memory) {
        if (listingId == 0) {
            revert();
        }
        uint256 listingIndex = listingId - 1;
        return allListings[listingIndex];
    }
}
