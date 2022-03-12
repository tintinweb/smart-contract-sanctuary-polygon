// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Validator {
    address[] public validators;
    // Fixed threshold to validate unlock/refund/emergency withdraw equal or more than 2/3 signatures
    uint256 public constant threshold = 66;

    event LogSubmitValidators(address[] validators);

    modifier validatorPrecheck(
        uint8[] memory _sigV,
        bytes32[] memory _sigR,
        bytes32[] memory _sigS
    ) {
        require(
            _sigV.length == _sigR.length &&
                _sigR.length == _sigS.length &&
                _sigV.length > 0,
            "validator(s) is empty"
        );

        require(
            (_sigV.length * 100) / validators.length >= threshold,
            "Threshold not reached"
        );

        if (_sigV.length >= 2) {
            for (uint256 i = 0; i < _sigV.length; i++) {
                for (uint256 j = i + 1; j < _sigV.length; j++) {
                    require(
                        keccak256(
                            abi.encodePacked(_sigV[i], _sigR[i], _sigS[i])
                        ) !=
                            keccak256(
                                abi.encodePacked(_sigV[j], _sigR[j], _sigS[j])
                            ),
                        "Can not be the same signature"
                    );
                }
            }
        }
        _;
    }

    constructor(address[] memory initValidators_) {
        validators = initValidators_;
    }

    function _checkSignature(
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _inputHash
    ) private view returns (bool) {
        address checkAdress = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _inputHash)
            ),
            _sigV,
            _sigR,
            _sigS
        );
        for (uint256 index = 0; index < validators.length; index++) {
            if (checkAdress == validators[index]) {
                return true;
            }
        }
        return false;
    }

    function checkRefundSig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 _nonce,
        uint256 _chainId
    ) external view validatorPrecheck(sigV, sigR, sigS) returns (bool) {
        bytes32 funcHash = keccak256("refund");

        // digest the data to transactionHash
        bytes32 inputHash = keccak256(abi.encode(funcHash, _nonce, _chainId));
        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    function checkSubmitRegisterChain(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address addressBank,
        uint256 _chainId
    ) external view validatorPrecheck(sigV, sigR, sigS) returns (bool) {
        bytes32 funcHash = keccak256("submitRegisterChain");

        bytes32 inputHash = keccak256(
            abi.encode(funcHash, addressBank, _chainId)
        );

        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    function checkSubmitValidator(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address[] memory _validators
    ) internal view validatorPrecheck(sigV, sigR, sigS) returns (bool) {
        bytes32 funcHash = keccak256("submitValidators");

        // digest the data to transactionHash
        bytes memory encode;
        for (uint256 i = 0; i < _validators.length - 1; i++) {
            abi.encode(validators[i], validators[i + 1]);
        }
        bytes32 inputHash = keccak256(abi.encode(funcHash, encode));
        for (uint256 index = 0; index < sigV.length; index++) {
            // address recoveredAddress = ecrecover(inputHash, sigV[index], sigR[index], sigS[index]);
            if (
                !_checkSignature(
                    sigV[index],
                    sigR[index],
                    sigS[index],
                    inputHash
                )
            ) return false;
        }
        return true;
    }

    function getValidators() external view returns (address[] memory) {
        return validators;
    }

    function submitValidators(
        address[] memory _validators,
        uint8[] memory _sigV,
        bytes32[] memory _sigR,
        bytes32[] memory _sigS
    ) external {
        for (uint256 i = 0; i < _validators.length; i++) {
            require(_validators[i] != address(0), "Null address");
        }
        require(
            checkSubmitValidator(_sigV, _sigR, _sigS, _validators),
            "invalid signature"
        );
        validators = _validators;
        emit LogSubmitValidators(validators);
    }
}