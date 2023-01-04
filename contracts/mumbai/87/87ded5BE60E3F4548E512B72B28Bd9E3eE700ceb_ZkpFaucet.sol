// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import "../common/Claimable.sol";
import "../common/ImmutableOwnable.sol";

// When called `drink`, it sends tokens to the `_to`
// As a prerequisite, it shall get enough tokens on the balance
contract ZkpFaucet is Claimable, ImmutableOwnable {
    address public immutable token;
    uint256 public cupSize;
    uint256 public tokenPrice;
    uint256 public maxAmountToPay;
    uint256 public maxDrinkCount;

    // @notice  store the whitelisted addresses who can drink
    mapping(address => bool) public whitelistedAddresses;
    // @notice store the number of times each user has drank
    mapping(address => uint256) public drinkCount;

    // @notice enabling/disabling check for whitelisted addresses
    bool public restrictToWhitelisted;

    event CupSizeUpdated(uint256 newCupSice);
    event TokenPriceUpdated(uint256 newTokenPrice);
    event MaxDrinkCountUpdated(uint256 newMaxDrinkCount);
    event WhitelistRestrictUpdated(bool newIsRestricted);

    constructor(
        address _owner,
        address _token,
        uint256 _tokenPrice,
        uint256 _maxAmountToPay,
        uint256 _cupSize,
        uint256 _maxDrinkCount
    ) ImmutableOwnable(_owner) {
        require(_cupSize > 0, "invalid cup size");
        require(_token != address(0), "invalid token address");

        token = _token;
        tokenPrice = _tokenPrice;
        cupSize = _cupSize;
        maxAmountToPay = _maxAmountToPay;
        maxDrinkCount = _maxDrinkCount;

        emit TokenPriceUpdated(_tokenPrice);
        emit CupSizeUpdated(_cupSize);
        emit MaxDrinkCountUpdated(_maxDrinkCount);
        emit WhitelistRestrictUpdated(false);
    }

    /**
     * @notice if restrictToWhitelisted is true, then
     * check if the sender is whitelisted
     */
    modifier onlyWhitelisted(address _address) {
        require(
            !restrictToWhitelisted || isWhitelisted(_address),
            "Not whitelisted"
        );
        _;
    }

    /**
     * @notice if maxDrinkCount is defined, then
     * check if the sender is already received token
     */
    modifier checkDrinkCount(address _address) {
        require(
            maxDrinkCount == 0 || withinDrinkLimit(_address),
            "Reached maximum drink count"
        );
        _;
    }

    /**
     * @notice if token price is more than 0, then
     * check the value
     */
    modifier validatePrice() {
        require(msg.value <= maxAmountToPay, "High value");
        require(msg.value >= tokenPrice, "Low value");
        _;
    }

    /**
     * @notice return true if the address is whitelisted, otherwise false
     * @dev it helps when contract is restricted to whitelisted addresses
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistedAddresses[_account];
    }

    /**
     * @notice return true if the user request counts are
     * less than or equal to maxDrinkCount, otherwise returns false
     * @dev it helps when contract is restricted to requests count.
     */
    function withinDrinkLimit(address _account) public view returns (bool) {
        return drinkCount[_account] < maxDrinkCount;
    }

    /**
     * @notice send tokens to `_to`
     * @param _to the receiver addresss
     * @dev if restrictToWhitelisted is true, then check if the
     * sender is whitelisted.
     * if the restrictToMaxReq is true, then check if the
     * sender is already received token.
     */
    function drink(address _to)
        external
        payable
        validatePrice
        onlyWhitelisted(msg.sender)
        checkDrinkCount(_to)
    {
        drinkCount[_to]++;

        safeTransfer(token, _to, getCupSize(msg.value));
    }

    function getCupSize(uint256 _amountToPay) public view returns (uint256) {
        return tokenPrice > 0 ? _amountToPay / tokenPrice : cupSize;
    }

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        // solhint-enable avoid-low-level-calls
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    // Owner functions
    /**
     * @notice update restrictToWhitelisted
     */
    function updateRestrictToWhitelisted(bool isRestricted) external onlyOwner {
        restrictToWhitelisted = isRestricted;
        emit WhitelistRestrictUpdated(isRestricted);
    }

    /**
     * @notice Add multiple addresses to the whitelisted list
     * @param _whitelistedAddresses array of addresses to be added
     * @param _whitelisted array of boolen values to be mapped to the addresses
     */
    function whitelistBatch(
        address[] calldata _whitelistedAddresses,
        bool[] calldata _whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < _whitelistedAddresses.length; ) {
            whitelistedAddresses[_whitelistedAddresses[i]] = _whitelisted[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice update the amount that can be received by users
     * @param _cupSize the amount that can be received by users
     */
    function updateCupSize(uint256 _cupSize) external onlyOwner {
        require(_cupSize > 0, "invalid size");
        cupSize = _cupSize;
        emit CupSizeUpdated(_cupSize);
    }

    /**
     * @notice update the token price.
     * @param _tokenPrice the price of each token
     */
    function updateTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit TokenPriceUpdated(_tokenPrice);
    }

    /**
     * @notice update the token price.
     * @param _maxDrinkCount the maximum number of times the
     * drink function can be called
     */
    function updateMaxDrinkCount(uint256 _maxDrinkCount) external onlyOwner {
        maxDrinkCount = _maxDrinkCount;
        emit MaxDrinkCountUpdated(_maxDrinkCount);
    }

    /**
     * @notice whithdraws native or erc20 token from the contract
     * @param _claimedToken The token address to claim
     * @param _to the receiver address
     * @param _amount the token amount to be withdrawn
     * @dev The token address can be zero address in case the
     * native token is going to be withdrawn.
     */
    function withdraw(
        address _claimedToken,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "recipient cannot be 0");
        require(_amount > 0, "amount cannot be 0");

        if (_claimedToken == address(0)) {
            // solhint-disable avoid-low-level-calls
            // slither-disable-next-line low-level-calls
            (bool sent, ) = _to.call{ value: _amount }("");
            // solhint-enable avoid-low-level-calls
            require(sent, "Failed to send native");
        } else {
            _claimErc20(_claimedToken, _to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

import "./TransferHelper.sol";

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens or ETH from this contract.
 */
abstract contract Claimable {
    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // withdraw ERC20
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    // disabled since false positive
    // slither-disable-next-line dead-code
    function _claimEthOrErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // withdraw ETH
            TransferHelper.safeTransferETH(to, amount);
        } else {
            // withdraw ERC20
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title TransferHelper library
/// @dev Helper methods for interacting with ERC20, ERC721, ERC1155 tokens and sending ETH
/// Based on the Uniswap/solidity-lib/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @dev Throws if the deployed code of the `token` is empty.
    // Low-level CALL to a non-existing contract returns `success` of 1 and empty `data`.
    // It may be misinterpreted as a successful call to a deployed token contract.
    // So, the code calling a token contract must insure the contract code exists.
    modifier onlyDeployedToken(address token) {
        uint256 codeSize;
        // slither-disable-next-line assembly
        assembly {
            codeSize := extcodesize(token)
        }
        require(codeSize > 0, "TransferHelper: zero codesize");
        _;
    }

    /// @dev Approve the `operator` to spend all of ERC720 tokens on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeSetApprovalForAll(
        address token,
        address operator,
        bool approved
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('setApprovalForAll(address,bool)'));
            abi.encodeWithSelector(0xa22cb465, operator, approved)
        );
        _requireSuccess(success, data);
    }

    /// @dev Get the ERC20 balance of `account`
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeBalanceOf(address token, address account)
        internal
        returns (uint256 balance)
    {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256(bytes('balanceOf(address)')));
            abi.encodeWithSelector(0x70a08231, account)
        );
        require(
            // since `data` can't be empty, `onlyDeployedToken` unneeded
            success && (data.length != 0),
            "TransferHelper: balanceOff call failed"
        );

        balance = abi.decode(data, (uint256));
    }

    /// @dev Approve the `spender` to spend the `amount` of ERC20 token on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('approve(address,uint256)'));
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transfer(address,uint256)'));
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer an ERC721 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc721SafeTransferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x42842e0e, from, to, tokenId)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `amount` ERC1155 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'));
            abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, _data)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` Ether from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferETH(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: ETH transfer failed");
    }

    function _requireSuccess(bool success, bytes memory res) private pure {
        require(
            success && (res.length == 0 || abi.decode(res, (bool))),
            "TransferHelper: token contract call failed"
        );
    }
}