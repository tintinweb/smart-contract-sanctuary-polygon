// SPDX-License-Identifier: -- DG --

pragma solidity =0.8.19;

import "./Interfaces.sol";
import "./TransferHelper.sol";
import "./AccessController.sol";
import "./EIP712MetaTransaction.sol";

contract TokenHub is
    AccessController,
    TransferHelper,
    EIP712MetaTransaction
{
    uint256 public forwardFrame;
    address public forwardAddress;

    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public forwardFrames;

    event Forward(
        address indexed depositorAddress,
        address indexed paymentTokenAddress,
        uint256 indexed paymentTokenAmount
    );

    constructor(
        address _defaultToken,
        uint256 _defaultFrame,
        address _defaultAddress
    )
        EIP712Base(
            "TokenHub",
            "v2.0"
        )
    {
        forwardFrame = _defaultFrame;
        forwardAddress = _defaultAddress;
        supportedTokens[_defaultToken] = true;
    }

    function forwardTokens(
        address _depositorAddress,
        address _paymentTokenAddress,
        uint256 _paymentTokenAmount
    )
        external
        onlyWorker
    {
        require(
            canDepositAgain(_depositorAddress),
            "TokenHub: DEPOSIT_COOLDOWN"
        );

        forwardFrames[_depositorAddress] = block.number;

        require(
            supportedTokens[_paymentTokenAddress],
            "TokenHub: UNSUPPORTED_TOKEN"
        );

        safeTransferFrom(
            _paymentTokenAddress,
            _depositorAddress,
            forwardAddress,
            _paymentTokenAmount
        );

        emit Forward(
            _depositorAddress,
            _paymentTokenAddress,
            _paymentTokenAmount
        );
    }

    function changeForwardFrame(
        uint256 _newDepositFrame
    )
        external
        onlyCEO
    {
        forwardFrame = _newDepositFrame;
    }

    function changeForwardAddress(
        address _newForwardAddress
    )
        external
        onlyCEO
    {
        forwardAddress = _newForwardAddress;
    }

    function changeSupportedToken(
        address _tokenAddress,
        bool _supportStatus
    )
        external
        onlyCEO
    {
        supportedTokens[_tokenAddress] = _supportStatus;
    }

    function canDepositAgain(
        address _depositorAddress
    )
        public
        view
        returns (bool)
    {
        return block.number - forwardFrames[_depositorAddress] >= forwardFrame;
    }
}