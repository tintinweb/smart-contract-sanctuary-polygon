//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PostBounty {
    string private greeting;
    address payable public author; // post author has privilege to send bounty
    // mogul takes  5% from each bounty and has privilege to add hunters
    address payable public mogul =
        payable(0xdf294464D3fAF933a1d864b6861475ab41B3Cf8F);
    uint256 public bounty;
    address payable[] public hunters; // list of wallets that have commented on post
    uint256 postExpiry;

    // Error where only the author can call this function
    error OnlyAuthor();
    // Error where only Mogul can call this function
    error OnlyMogul();
    // Error where Post has passed expiry date
    error NotExpired();

    // author opens smart contract
    constructor() payable {
        author = payable(msg.sender);
        bounty = msg.value;
        // post expires after 1 week (test value 1 minute)
        postExpiry = block.timestamp + 1 minutes;
    }

    modifier onlyAuthor() {
        if (msg.sender != author) revert OnlyAuthor();
        _;
    }
    modifier onlyMogul() {
        if (msg.sender != mogul) revert OnlyMogul();
        _;
    }

    modifier postExpired() {
        if (block.timestamp < postExpiry) revert NotExpired();
        _;
    }

    function addHunter(address payable hunter) public onlyMogul {
        hunters.push(hunter);
    }

    function payHunter(address payable[] memory paid_hunters)
        public
        onlyAuthor
    {
        for (uint256 i = 0; i < paid_hunters.length; i++) {
            paid_hunters[i].transfer(bounty / paid_hunters.length);
        }
    }

    function splitBounty() public onlyMogul postExpired {
        for (uint256 i = 0; i < hunters.length; i++) {
            hunters[i].transfer(bounty / hunters.length);
        }
    }
}