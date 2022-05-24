// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IGovEmergencyCreator.sol";
import "./ISale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GovEmergency{
    address public immutable komv;
    address public immutable gov = msg.sender;

    uint128 public start;
    uint128 public end;

    address[] public candidates;

    bool private initialized;
    address public owner = tx.origin;

    string public name;

    mapping(address => bool) public registered;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(){
        komv = IGovEmergencyCreator(gov).komv();
    }

    function initialize(
        string calldata _name,
        uint128 _start,
        uint128 _end
    ) external {
        require(!initialized, "initialized");
        require(msg.sender == gov, "!gov");

        name = _name;
        start = _start;
        end = _end;

        initialized = true;
    }

    function getCandidateLength() external view returns (uint) {
        return candidates.length;
    }

    function migrate(
        address _saleTarget,
        address[] calldata _from,
        uint128[] calldata _votedAt
    ) external onlyOwner {
        require(_saleTarget != address(0) && _from.length == _votedAt.length && block.timestamp > end, "bad");

        for(uint i=0; i<_from.length; i++){
            if(
                registered[_from[i]] ||
                IERC20(komv).balanceOf(_from[i]) == 0 ||
                _votedAt[i] < start ||
                _votedAt[i] > end
            ) continue;

            registered[_from[i]] = true;
            candidates.push(_from[i]);
        }

        require(ISale(_saleTarget).migrateCandidates(candidates), "fail");
    }

    function updateStart(uint128 _start) external onlyOwner {
        require(_start != 0 && block.timestamp < start, "bad");
        start = _start;
    }

    function updateEnd(uint128 _end) external onlyOwner {
        require(_end != 0 && block.timestamp < end, "bad");
        end = _end;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGovEmergencyCreator{
    event RegistrationCreated(address indexed registration, uint index);
    
    function owner() external  view returns (address);
    
    function komv() external  view returns (address);
    
    function allRegistrationsLength() external view returns(uint);
    
    function allRegistrations(uint) external view returns(address);

    function createRegistration(string calldata, uint128, uint128) external returns (address);
    
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISale{
    function migrateCandidates(address[] calldata) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}