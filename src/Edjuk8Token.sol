// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Edjuk8Token is ERC20 {
    constructor() ERC20("Edjuk8 Token", "EDJ-8") {}

    function mintFree(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burnFree(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
