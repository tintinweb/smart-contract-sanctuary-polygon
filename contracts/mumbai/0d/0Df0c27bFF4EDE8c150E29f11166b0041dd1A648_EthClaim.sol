/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;


contract EthClaim {
    using Math for uint256;

    address public owner;
    uint256 public claimEnds;
    bool public isActive;

    uint256 private totalBalance;
    uint256 public totalAmount;

    mapping(address => bool) private _claims;
    mapping(address => uint256) private _amounts;

    constructor(uint256 _totalAmount, address[] memory _users, uint256[] memory amounts) payable {
        require(_users.length == amounts.length, "Invalid data");
        for(uint256 i = 0; i < _users.length; i++) {
            _amounts[_users[i]] = amounts[i];
        }
        owner = msg.sender;
        claimEnds = block.timestamp + (365 * 86400);
        totalAmount = _totalAmount;
    }

    receive() external payable {}
    fallback() external payable {}

    function start() public {
        require(msg.sender == owner, "Not owner");
        require(!isActive, "Contract already active");
        isActive = true;
        totalBalance = address(this).balance;
    }

    function getAmountToClaim(address _user) public view returns (uint256) {
        uint256 amount = _amounts[_user];
        uint256 percentOfTotal = amount.mulDivDown(1e18, totalAmount);
        uint256 amountToSend = totalBalance.mulDivDown(percentOfTotal, 1e18);

        return amountToSend;
    }

    function claim() external returns (uint256) {
        require(block.timestamp < claimEnds, "Claiming is over");
        require(!_claims[msg.sender], "Already claimed");

        uint256 amountToSend = getAmountToClaim(msg.sender);

        require(amountToSend < address(this).balance, "Amount exceeds contract balance");
        require(amountToSend > 0, "Amount cannot be 0");

        _claims[msg.sender] = true;

        (bool sent, ) = payable(msg.sender).call{value: amountToSend}("");

        require(sent, "Failed to send ETH");

        return amountToSend;        
    }

    function checkClaimed(address account) public view returns (bool)
    {
        return _claims[account];
    }

    function setClaimEnd(uint256 _claimEndTime) public {
        require(_claimEndTime > block.timestamp, "Claim end can't be in the past");
        claimEnds = _claimEndTime;
    }

    function withdrawLeftover() public
    {
        require(msg.sender == owner, "Not owner");
        require(block.timestamp > claimEnds, "Claiming not done yet");

        isActive = false;

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        
        require(sent, "Failed to send ETH");
    }
}

library Math {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}
// File: contracts/EthClaim.sol