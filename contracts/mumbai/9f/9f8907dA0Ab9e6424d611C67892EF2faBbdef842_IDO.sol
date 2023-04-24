// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {IERC20} from "../interfaces/IERC20.sol";
import {IIDO, Token} from "../interfaces/IIDO.sol";

contract IDO is IIDO {
    address public immutable owner;

    uint public immutable price;
    uint public immutable hardcap;
    uint public immutable investMax;
    uint public immutable investMin;
    uint public immutable claimStart;
    uint public immutable saleStart;
    uint public immutable saleEnd;

    bool public s_halted;
    uint public s_raised;
    Token public s_idoToken;
    address payable public s_deposit;
    mapping(address => uint) public s_claims;

    constructor(
        address payable _deposit,
        Token memory _idoToken,
        uint _price,
        uint _hardcap,
        uint _investMax,
        uint _investMin
    ) {
        owner = msg.sender;
        s_idoToken = _idoToken;
        s_deposit = _deposit;
        saleStart = block.timestamp + 1 hours;
        saleEnd = block.timestamp + 1 weeks;
        claimStart = saleEnd + 1 weeks;

        price = _price;
        hardcap = _hardcap;
        investMax = _investMax;
        investMin = _investMin;
    }

    function invest() public payable notHalted {
        require(block.timestamp >= saleStart, "!started");
        require(block.timestamp <= saleEnd, "ended");
        require(s_raised < hardcap, "raised > hardcap");
        require(msg.value >= investMin, "< min amount");
        require(msg.value <= investMax, "> max amount");

        uint _claimAmount = (msg.value / price) * 10 ** s_idoToken.decimals;

        IERC20(s_idoToken.addr).transferFrom(
            owner,
            address(this),
            _claimAmount
        ); // This contract assumes IDO contract and Erc20 contract have same owner

        s_claims[msg.sender] += _claimAmount;
        s_deposit.transfer(msg.value);

        emit Invested(msg.sender, msg.value, s_claims[msg.sender]);
    }

    function claim() external notHalted {
        require(block.timestamp >= claimStart, "!time");

        uint _claims = s_claims[msg.sender];

        require(_claims > 0);

        s_claims[msg.sender] = 0;

        IERC20(s_idoToken.addr).transfer(msg.sender, _claims);

        emit Claimed(msg.sender, _claims);
    }

    function burn() external {
        require(block.timestamp >= saleEnd);

        /* 
            @notice there is a slight chance that raised amount exceeds hardcap by a 
            maximum of investMax - investMin, so an implicit conversion to int is needed here
         */

        int _toBurn = int(hardcap - s_raised);

        require(_toBurn > 0);

        IERC20(s_idoToken.addr).transferFrom(owner, address(0), uint(_toBurn));
    }

    receive() external payable {
        invest();
    }

    function setDeposit(address payable _addr) external Owner {
        s_deposit = _addr;
    }

    function halt() external Owner {
        s_halted = true;
    }

    function resume() external Owner {
        s_halted = false;
    }

    modifier notHalted() {
        require(!s_halted);
        _;
    }

    modifier Owner() {
        _isOwner();
        _;
    }

    function _isOwner() internal view {
        require(msg.sender == owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Token {
    address addr;
    uint decimals;
}

interface IIDO {
    event Claimed(address indexed investor, uint amount);
    event Invested(address indexed investor, uint amount, uint claims);

    /**
     * @notice Invest in the IDO and claim tokens once the sale is over
     * @dev Callable only when the sale is active and not halted
     * @dev The invested ETH will be sent to the IDO contract deposit address
     * @dev The investor will receive claimAmount of IDO tokens proportional to the invested amount
     * @dev Claim tokens will be locked in this contract till the claimStart time
     * @dev The s_idoToken owner must have sufficient balance and allowance for this contract for invest to proceed
     * @dev Emits Invested event on successful investment
     */
    function invest() external payable;

    /**
     * @notice Claim IDO tokens proportional to the invested amount
     * @dev Callable only after the claim start time and not halted
     * @dev The IDO tokens will be transferred from the IDO contract to the investor
     * @dev Emits Claimed event on successful claim
     */
    function claim() external;

    /**
     * @notice Burn excess IDO tokens after the sale ends
     * @dev Callable only after the sale end time
     * @dev The IDO tokens will be transferred from the IDO contract to the zero address
     */
    function burn() external;

    /**
     * @notice Update the IDO contract deposit address
     * @dev Callable only by the contract owner
     * @param _addr The new deposit address
     */
    function setDeposit(address payable _addr) external;

    /**
     * @notice Halt the IDO contract
     * @dev Callable only by the contract owner
     */
    function halt() external;

    /**
     * @notice Resume the IDO contract
     * @dev Callable only by the contract owner
     */
    function resume() external;

    /**
     * @notice Check if the IDO contract is halted
     * @return True if the IDO contract is halted, otherwise false
     */
    function s_halted() external view returns (bool);

    /**
     * @notice Get the amount of ETH raised in the IDO so far
     * @return The amount of ETH raised
     */
    function s_raised() external view returns (uint);

    /**
     * @notice Get the IDO token contract address and decimals
     * @return The IDO token contract address and decimals
     */
    function s_idoToken() external view returns (address, uint);

    /**
     * @notice Get the IDO contract deposit address
     * @return The IDO contract deposit address
     */
    function s_deposit() external view returns (address payable);

    /**
     * @notice Get the amount of pending claims of an investor
     * @param _addr The investor address
     * @return The amount of pending claims of an investor
     */
    function s_claims(address _addr) external view returns (uint);
}