// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IMasterHealer.sol";

contract AmysStakingCo {
    using Address for address;

    error UnknownChefType(address chef);
    error PoolLengthZero(address chef);

    uint8 constant CHEF_UNKNOWN = 0;
    uint8 constant CHEF_MASTER = 1;
    uint8 constant CHEF_MINI = 2;
    uint8 constant CHEF_STAKING_REWARDS = 3;
    uint8 constant OPERATOR = 255;

    function getMCPoolData(address chef) external view returns (uint8 chefType, address[] memory lpTokens, uint256[] memory allocPoint, uint256[] memory endTime) {

        chefType = identifyChefType(chef);
        uint len = getLength(chef, chefType);
        if (len == 0) revert PoolLengthZero(chef);

        lpTokens = new address[](len);
        allocPoint = new uint256[](len);

        if (chefType == CHEF_MASTER) {
            for (uint i; i < len; i++) {
                (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", i));
                if (success) (lpTokens[i], allocPoint[i]) = abi.decode(data,(address, uint256));
            }
        } else if (chefType == CHEF_MINI) {
            for (uint i; i < len; i++) {
                (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", i));
                if (!success) continue;
                lpTokens[i] = abi.decode(data,(address));

                (success, data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", i));
                if (success) (,, allocPoint[i]) = abi.decode(data,(uint128,uint64,uint64));
            }
        } else if (chefType == CHEF_STAKING_REWARDS) {
            endTime = new uint256[](len);
            for (uint i; i < len; i++) {
                address spawn = addressFrom(chef, i + 1);
                assembly {
                    if iszero(extcodesize(spawn)) {
                        spawn := 0
                    }
                }
                if (spawn == address(0)) continue;

                (bool success, bytes memory data) = spawn.staticcall(abi.encodeWithSignature("stakingToken()"));
                if (!success) continue;
                lpTokens[i] = abi.decode(data,(address));

                (success, data) = spawn.staticcall(abi.encodeWithSignature("periodFinish()"));
                if (!success) continue;
                uint _endTime = abi.decode(data,(uint256));
                endTime[i] = _endTime;
                if (_endTime < block.timestamp) continue;

                (success, data) = spawn.staticcall(abi.encodeWithSignature("rewardRate()"));
                if (success) (,, allocPoint[i]) = abi.decode(data,(uint128,uint64,uint64));
            }
        }

    }

    function getLength(address chef, uint8 chefType) public view returns (uint len) {
        if (chefType == CHEF_MASTER || chefType == CHEF_MINI) {
                len = IMasterHealer(chef).poolLength();
            } else if (chefType == CHEF_STAKING_REWARDS) {
                len = createFactoryNonce(chef) - 1;
            }
    }

    //assumes at least one pool exists i.e. chef.poolLength() > 0
    function identifyChefType(address chef) public view returns (uint8 chefType) {

        (bool success,) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", 0));

        if (success && checkMiniChef(chef)) {
            return CHEF_MINI;
        }
        if (!success && checkMasterChef(chef)) {
            return CHEF_MASTER;
        }
        if (checkStakingRewardsFactory(chef)) {
            return CHEF_STAKING_REWARDS;
        }
        
        revert UnknownChefType(chef);
    }

    function checkMasterChef(address chef) internal view returns (bool valid) { 
        (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", 0));
        if (!success) return false;
        (uint lpTokenAddress,,uint lastRewardBlock) = abi.decode(data,(uint256,uint256,uint256));
        valid = ((lpTokenAddress > type(uint96).max && lpTokenAddress < type(uint160).max) || lpTokenAddress == 0) && 
            lastRewardBlock <= block.number;
    }

    function checkMiniChef(address chef) internal view returns (bool valid) { 
        (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("poolInfo(uint256)", 0));
        if (!success) return false;
        (success,) = chef.staticcall(abi.encodeWithSignature("lpToken(uint256)", 0));
        if (!success || data.length < 0x40) return false;

        (,uint lastRewardTime) = abi.decode(data,(uint256,uint256));
        valid = lastRewardTime <= block.timestamp && lastRewardTime > 2**30;
    }

    function checkStakingRewardsFactory(address chef) internal view returns (bool valid) {
        (bool success, bytes memory data) = chef.staticcall(abi.encodeWithSignature("stakingRewardsGenesis()"));
        valid = success && data.length == 32;
    }

    function addressFrom(address _origin, uint _nonce) private pure returns (address) {
        bytes32 data;
        if(_nonce == 0x00)          data = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80)));
        else if(_nonce <= 0x7f)     data = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce)));
        else if(_nonce <= 0xff)     data = keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce)));
        else if(_nonce <= 0xffff)   data = keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce)));
        else if(_nonce <= 0xffffff) data = keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce)));
        else                        data = keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce))); // more than 2^32 nonces not realistic

        return address(uint160(uint256(data)));
    }

    //The nonce of a factory contract that uses CREATE, assuming no child contracts have selfdestructed
    function createFactoryNonce(address _origin) public view returns (uint) {

        uint n = 1;
        uint top = 2**32;
    
        unchecked {
            for (uint p = 1; p < top && p > 0;) {
                address spawn = addressFrom(_origin, n + p); //
                if (spawn.isContract()) {
                    n += p;
                    p *= 2;
                    if (n + p > top) p = (top - n) / 2;
                } else {
                    top = n + p;
                    p /= 2;
                }
            }
            return n;
        }
    }

    struct LPTokenInfo {
        bool isLPToken;
        address token0;
        address token1;
        address factory;
        bytes32 symbol;
        bytes32 token0symbol;
        bytes32 token1symbol;
    }

    function lpTokenInfo(address token) public view returns (LPTokenInfo memory info) {
        (bool isLP, address token0, address token1, address factory) = checkLP(token);
        info = LPTokenInfo({
            isLPToken: isLP,
            token0: token0,
            token1: token1,
            factory: factory,
            symbol: getSymbol(token),
            token0symbol: getSymbol(token0),
            token1symbol: getSymbol(token1)
        });
    }

    function getSymbol(address token) internal view returns (bytes32) {
        if (token == address(0)) return bytes32(0);
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (!success) return bytes32(0);
        return bytes32(bytes(abi.decode(data,(string))));
    }

    function lpTokenInfo(address[] memory tokens) public view returns (LPTokenInfo[] memory info) {
        info = new LPTokenInfo[](tokens.length);
        for (uint i; i < tokens.length; i++) {
            info[i] = lpTokenInfo(tokens[i]);
        }
    }

    function checkLP(address token) public view returns (bool isLP, address token0, address token1, address factory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("token0()"));
        if (!success || data.length < 32) return (false, address(0), address(0), address(0));
        token0 = abi.decode(data,(address));

        (success, data) = token.staticcall(abi.encodeWithSignature("token1()"));
        if (token0 == address(0) || !success || data.length < 32) return (false, address(0), address(0), address(0));
        token1 = abi.decode(data,(address));

        (success, data) = token.staticcall(abi.encodeWithSignature("factory()"));
        if (token1 == address(0) || !success || data.length < 32) return (false, address(0), address(0), address(0));
        factory = abi.decode(data,(address));

        (success, data) = factory.staticcall(abi.encodeWithSignature("getPair(address,address)", token0, token1));
        if (factory == address(0) || !success || data.length < 32) return (false, address(0), address(0), address(0));
        address pairFound = abi.decode(data,(address));
        
        if (pairFound == token) return (true, token0, token1, factory);
        else return (false, address(0), address(0), address(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
interface IMasterHealer {
    function crystalPerBlock() external view returns (uint256);
    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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