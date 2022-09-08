/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Treasury {

    struct Vote {
        address caller;
        address payable to;
        uint256 blockStamp;
        uint256 amount;
        uint8 yay;
        uint8 nay;
        string currency;
    }

    address public immutable treasurer1;
    address public immutable treasurer2;
    address public immutable treasurer3;
    address public immutable treasurer4;

    ERC20 private constant USDC = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    bool public isVoteActive;

    Vote public voteObject = Vote(address(0), payable(address(0)), 0, 0, 0, 0, "");

    event VoteCast(address caller, string vote);
    event VoteStarted(address caller, address to, uint256 amount, string currency);

    constructor(address _treasurer1, address _treasurer2, address _treasurer3, address _treasurer4) {
        treasurer1 = _treasurer1;
        treasurer2 = _treasurer2;
        treasurer3 = _treasurer3;
        treasurer4 = _treasurer4;
    }

    receive() external payable { 
        require(msg.value > 0, "You must send some ETH");
    }

    function getTreasurers () public view returns (address[] memory) {
        address[] memory treasurers = new address[](4);
        treasurers[0] = treasurer1;
        treasurers[1] = treasurer2;
        treasurers[2] = treasurer3;
        treasurers[3] = treasurer4;
        return treasurers;
    }

    function callTransferOut ( address payable to, uint256 amount, string memory currency) external {
        require(!isVoteActive, "There is an active vote");
        require(msg.sender == treasurer1 || msg.sender == treasurer2 || msg.sender == treasurer3 || msg.sender == treasurer4, "You are not a treasurer");
        require(compareStrings(currency, "NATIVE") || compareStrings(currency, "USDC"), "Invalid currency");

        isVoteActive = true;
        voteObject = Vote(msg.sender, to, block.number, amount, 0, 0, currency);
        emit VoteStarted(msg.sender, to, amount, currency);
    }

    function castVote(string memory _vote) external {
        require(msg.sender == treasurer1 || msg.sender == treasurer2 || msg.sender == treasurer3 || msg.sender == treasurer4, "You are not a treasurer");
        require(isVoteActive, "There is no active vote");

        if (compareStrings(_vote, "YAY")) {
            voteObject.yay++;
            emit VoteCast(msg.sender, _vote);
        } else if (compareStrings(_vote, "NAY")) {
            voteObject.nay++;
            emit VoteCast(msg.sender, _vote);

            if (voteObject.nay > 1) {
                isVoteActive = false;
                voteObject = Vote(address(0), payable(address(0)), 0, 0, 0, 0, "");
            }
        } else {
            revert("Invalid vote");
        }
    }

    function executeTransfer() public {
        require(isVoteActive, "There is no active vote");
        require(voteObject.yay > 1, "Not enough YAY votes");

        if (compareStrings(voteObject.currency, "NATIVE")) {
            (bool success,) = voteObject.to.call{value: voteObject.amount}("");
            require(success, "Transfer failed");
        } else {
            USDC.transfer(voteObject.to, voteObject.amount);
        }

        isVoteActive = false;
        voteObject = Vote(address(0), payable(address(0)), 0, 0, 0, 0, "");
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}