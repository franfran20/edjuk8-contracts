// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface IShareMarketPlace {
    // Externa Functions

    function buyShares(uint256 listingId) external payable;

    function sellShares(address user, uint256 shareAmount, uint256 courseId, uint256 price)
        external
        returns (uint256);

    function canceShareListing(uint256 listingId) external;

    // Getter Functions

    function getAllShareListings() external view returns (Types.ShareListing[] memory);

    function getShareListingById(uint256 listingId) external view returns (Types.ShareListing memory);
}
