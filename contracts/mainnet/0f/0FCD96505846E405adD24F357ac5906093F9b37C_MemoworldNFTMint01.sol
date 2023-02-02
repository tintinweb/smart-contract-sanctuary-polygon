// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6 <0.9.0;
pragma abicoder v2;

import {IMemoworldNFT} from "IMemoworldNFT.sol";

contract MemoworldNFTMint01 {
    // Address representating ETH (e.g. in payment routing paths)
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Indicates that this plugin requires delegate call
    bool public immutable delegate = true;

    event RouteMint(
        address indexed sender,
        uint256 indexed tokenId,
        uint256 indexed amount,
        string data
    );

    constructor() {}

    function execute(
        address[] calldata path,
        uint256[] calldata amounts,
        address[] calldata addresses,
        string[] calldata data
    ) external payable returns (bool) {
        IMemoworldNFT memoContract = IMemoworldNFT(
            addresses[addresses.length - 1]
        );

        memoContract.mint{value: amounts[1]}(
            addresses[0],
            amounts[5],
            amounts[6],
            data[0]
        );

        emit RouteMint(addresses[0], amounts[5], amounts[6], data[0]);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6 <0.9.0;

interface IMemoworldNFT {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        string memory data
    ) external payable;
}