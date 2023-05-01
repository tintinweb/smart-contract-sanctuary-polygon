// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;

interface ILayerZeroUltraLightNodeV1 {

    /// an Oracle delivers the block data using updateBlockHeader()
    function updateHash(uint16 _remoteChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _data) external;
    /// oracle can withdraw their fee from the ULN which accumulates native tokens per call
    function withdrawOracleFee(address _to, uint _amount) external;

    //    /// un-used by Oracle
    //    function validateTransactionProof(uint16 _srcChainId, address _dstAddress, uint _gasLimit, bytes calldata _blockHash, bytes calldata _transactionProof) external;
    //    function withdrawTreasuryFee(address _to, uint _amount, bool _inNative) external;
    //    function withdrawRelayerFee(address _owner, address _to, uint _amount, bool _inNative, bool _quoted) external;

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ILayerZeroUltraLightNodeV1.sol";

// this is a mocked LayerZero UltraLightNodeMock that receives the blockHash and receiptsRoot
contract UltraLightNodeMock is ILayerZeroUltraLightNodeV1, ReentrancyGuard {

    // oracle fees will accumulate in the LayerZero contract
    mapping(address => uint) public oracleQuotedFees;
    mapping(address => mapping(uint16 => mapping(bytes32 => BlockData))) public hashLookup;


    struct BlockData {
        uint          confirmations;
        bytes32        data;
    }

    event HashReceived(uint16 srcChainId, address oracle, uint confirmations, bytes32 blockhash);
    event WithdrawNative(address _owner, address _to, uint _amount);

    mapping(address => mapping(uint16 => mapping(bytes32 => BlockData))) public blockHeaderLookup;

    // Can be called by any address to update a block header
    // can only upload new block data or the same block data with more confirmations
    function updateHash(uint16 _remoteChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _data) external override {
        // this function may revert with a default message if the oracle address is not an ILayerZeroOracle
        BlockData storage bd = hashLookup[msg.sender][_remoteChainId][_lookupHash];
        // if it has a record, requires a larger confirmation.
        require(bd.confirmations < _confirmations, "LayerZero: oracle data can only update if it has more confirmations");

        // set the new information into storage
        bd.confirmations = _confirmations;
        bd.data = _data;

        emit HashReceived(_remoteChainId, msg.sender, _confirmations, _lookupHash);
    }

    function withdrawOracleFee(address _to, uint _amount) override nonReentrant external {
        oracleQuotedFees[msg.sender] = oracleQuotedFees[msg.sender] - _amount;
        _withdrawNative(msg.sender, _to, _amount);
    }

    //---------------------------------------------------------------------------
    // Claim Fees
    function _withdrawNative(address _from, address _to, uint _amount) internal {
        (bool success, ) = _to.call{value: _amount}('');
        require(success, "LayerZero: withdraw failed");
        emit WithdrawNative(_from, _to, _amount);
    }
}