// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract Errors {
    error Edjuk8__InvalidSigDeadline();
    error Edjuk8__AlreadyRegistered();
    error Edjuk8__UsernameTaken();
    error Edjuk8__UsernameCharactersExceeded();
    error InsufficientCourseCreationFee();
    error Edjuk8__UserHasZeroShares();
    error Edjuk8__InsufficentSharesBalance();
    error Edjuk8__MaxSubCoursePriceExceeded();
    error Edjuk8__InvalidSharesAmountBalance();
    error Edjuk8__NotAShareHolder();
    error Edjuk8__UserIsNotAShareHolder();
    error Edjuk8__TokenTransferFailed();
    error Edjuk8__CantTransferShareToSelf();
    error Edjuk8__NotCourseOwner();
    error Edjuk8__UserMaxCourseExceeded();
    error Edjuk9__OwnerCantHaveLessThanMinimumPercentShare();
    error Edjuk8__InsufficientTokenAllowance();
    error Edjuk8__InsuficientTokenBalance();
    error Edjuk8__CallerIsNotSubCourse();
    error Edjuk8__MaxAllowedSubCoursesExceeded();
    error Edjuk8__InvalidCourseId();
    error Edjuk8__InvalidSigner();
    error Edjuk8__UserRegistered();
    error Edjuk8__NotRegistered();
    error Edjuk8__SharesToSellCannotBeZero();
    error Edjuk8__InsufficientBalanceOrAllowanceForListing();
    error SharesToCashInCannotBeZero();

    // market place
    error Edjuk8__UserCourseSharesAlreadyOnSale();
    error Edjuk8__CantBuyYourOwnShares();
    error Edjuk8__ListingDoesNotExist();
    error Edjuk8__ListingNotAvailableAnymore();
    error Edjuk8__ListingValuationNotMet();
    error Edjuk8__InvalidCaller();

    // subcourse

    error Edjuk8__MaxAmountOfLessonsCreated();
    error Edjuk8__UserAlreadyEnrolled();
    error Edjuk8__UserAlreadyReviewed();
    error Edjuk8__UserNotEnrolled();
    error Edjuk8__InvalidLessonID();
}
