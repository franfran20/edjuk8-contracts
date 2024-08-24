// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface IShareMarketPlace {
    // sends a buy share request to the course handler and updates all the share owner amount and details
    // remember to only allow talking between the course handler and marketplace for this fucntion

    function buyShares(uint256 listingId) external payable;

    // sell shares
    // forwards to the ccourse handler who handles checs for the msg.sender from here
    // remember to only allow talking between the course handler and marketplace for this fucntion
    // can only have one sale at a time

    // only callable by course handler
    function sellShares(address user, uint256 shareAmount, uint256 courseId, uint256 price)
        external
        returns (uint256);

    // drop a users share sale
    // use munchable remove from array
    function canceShareListing(uint256 listingId) external;

    // getter functions

    function getAllShareListings() external view returns (Types.ShareListing[] memory);

    function getShareListingById(uint256 listingId) external view returns (Types.ShareListing memory);

    event CourseSharesListed(address user, uint256 courseId, uint256 shareAmount);

    event SharesPurchased(address user, uint256 listingId, uint256 courseId, uint256 shareAmount);
}
