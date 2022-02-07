pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ECVerify.sol";
import "./AppraisalStruct.sol";

/**
 * @title MetaLend's AppraisalOracle Contract
 * @notice Validates appraisals and data created off-chain
 * @author MetaLend
 */
contract AppraisalOracle {
    using ECVerify for bytes32;

    address public admin;

    address _appraiser;

    constructor() public {
        admin = msg.sender;
    }

    /**
     * @notice Checks if address is current appraiser
     * @param _address The address to check
     * @return Whether the address is the current appraiser
     */
    function _isAppraiser(address _address) public view returns (bool) {
        return _appraiser == _address;
    }

    /**
     * @notice Sets the address of the appraiser
     * @param newAppraiser The address to set
     */
    function _setAppraiser(address newAppraiser) external {
        require(msg.sender == admin);
        _appraiser = newAppraiser;
    }

    /**
     * @notice Checks if the data was created by the current appraiser
     * @param hash The hash of data to check
     * @param signature The signature to check
     * @return Whether the data was created by the current appraiser
     */
    function verifySignature(
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        address signer = hash.recover(signature);
        return _isAppraiser(signer);
    }

    /**
     * @notice Checks if the appraisal was created by the current appraiser
     * @param wire The appraisal data to check
     * @return Whether the appraisal was created by the current appraiser
     */
    function verifyAppraisals(
        AppraisalStruct.Wire calldata wire
    ) external view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                wire.appraisalTokens,
                wire.appraisalLengths,
                wire.appraisalTokenIds,
                wire.appraisalValues,
                wire.appraisalGoodUntil
            )
        );
        return verifySignature(hash, wire.signature) &&
            wire.appraisalGoodUntil >= getBlockNumber() &&
            wire.appraisalTokens.length == wire.appraisalLengths.length &&
            wire.appraisalTokenIds.length == wire.appraisalValues.length;
    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @notice Appraisal created off-chain
 * appraisalTokens: list of CErc721 token addresses
 * appraisalLengths: list of count of tokenIds per CErc721 token
 * appraisalTokenIds: list of tokenIds across the CErc721 tokens
 * appraisalGoodUntil: the block number when this appraisal expires
 * signature: the signature created by the off-chain appraiser
 */
library AppraisalStruct {
    struct Wire {
        address[] appraisalTokens;
        uint[] appraisalLengths;
        uint[] appraisalTokenIds;
        uint[] appraisalValues;
        uint appraisalGoodUntil;
        bytes signature;
    }
}

pragma solidity ^0.5.16;

library ECVerify {

    enum SignatureMode {
        EIP712,
        GETH,
        TREZOR
    }

    function recover(bytes32 _hash, bytes memory _signature) internal pure returns (address _signer) {
        return recover(_hash, _signature, 0);
    }

    // solium-disable-next-line security/no-assign-params
    function recover(bytes32 _hash, bytes memory _signature, uint256 _index) internal pure returns (address _signer) {
        require(_signature.length >= _index + 66);

        SignatureMode _mode = SignatureMode(uint8(_signature[_index]));
        bytes32 _r;
        bytes32 _s;
        uint8 _v;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _r := mload(add(_signature, add(_index, 33)))
            _s := mload(add(_signature, add(_index, 65)))
            _v := and(255, mload(add(_signature, add(_index, 66))))
        }

        if (_v < 27) {
            _v += 27;
        }

        require(_v == 27 || _v == 28);

        if (_mode == SignatureMode.GETH) {
            _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        } else if (_mode == SignatureMode.TREZOR) {
            _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n\x20", _hash));
        }

        return ecrecover(_hash, _v, _r, _s);
    }
}