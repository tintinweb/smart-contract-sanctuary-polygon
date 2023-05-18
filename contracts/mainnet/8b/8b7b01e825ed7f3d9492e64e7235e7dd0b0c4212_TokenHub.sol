// SPDX-License-Identifier: -- DG --

pragma solidity =0.8.19;

import "./EIP712MetaTransaction.sol";
import "./AccessController.sol";
import "./TransferHelper.sol";
import "./Interfaces.sol";

contract TokenHub is
    AccessController,
    TransferHelper,
    EIP712MetaTransaction
{
    uint256 public depositFrame;
    address public withdrawAddress;

    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public userFrames;
    mapping(address => mapping(address => uint256)) public userPurchases;

    event Deposit(
        address indexed depositorAddress,
        address indexed paymentTokenAddress,
        uint256 indexed paymentTokenAmount
    );

    event Withdraw(
        address indexed withdrawToken,
        uint256 indexed withdrawAmount,
        address indexed withdrawAddress
    );

    event Spend(
        address indexed spendToken,
        uint256 indexed spendAmount,
        address indexed spendAddress
    );

    constructor(
        address _defaultToken,
        uint256 _defaultFrame,
        address _defaultAddress
    )
        EIP712Base(
            "TokenHub",
            "v1.0"
        )
    {
        supportedTokens[_defaultToken] = true;
        withdrawAddress = _defaultAddress;
        depositFrame = _defaultFrame;
    }

    function depositTokens(
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

        userFrames[_depositorAddress] = block.number;

        require(
            supportedTokens[_paymentTokenAddress],
            "TokenHub: UNSUPPORTED_TOKEN"
        );

        safeTransferFrom(
            _paymentTokenAddress,
            _depositorAddress,
            address(this),
            _paymentTokenAmount
        );

        userPurchases[_depositorAddress][_paymentTokenAddress] += _paymentTokenAmount;

        emit Deposit(
            _depositorAddress,
            _paymentTokenAddress,
            _paymentTokenAmount
        );
    }

    function withdrawTokens(
        address _depositorAddress,
        address _paymentTokenAddress,
        uint256 _paymentTokenAmount
    )
        external
        onlyWorker
    {
        safeTransfer(
            _paymentTokenAddress,
            _depositorAddress,
            _paymentTokenAmount
        );

        userPurchases[_depositorAddress][_paymentTokenAddress] -= _paymentTokenAmount;

        emit Withdraw(
            _paymentTokenAddress,
            _paymentTokenAmount,
            _depositorAddress
        );
    }

    function spendTokens(
        address _depositorAddress,
        address _paymentTokenAddress,
        uint256 _paymentTokenAmount
    )
        external
        onlyWorker
    {
        safeTransfer(
            _paymentTokenAddress,
            withdrawAddress,
            _paymentTokenAmount
        );

        userPurchases[_depositorAddress][_paymentTokenAddress] -= _paymentTokenAmount;

        emit Spend(
            _paymentTokenAddress,
            _paymentTokenAmount,
            withdrawAddress
        );
    }

    function changeDepositFrame(
        uint256 _newDepositFrame
    )
        external
        onlyCEO
    {
        depositFrame = _newDepositFrame;
    }

    function changeWithdrawAddress(
        address _newWithdrawAddress
    )
        external
        onlyCEO
    {
        withdrawAddress = _newWithdrawAddress;
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
        return block.number - userFrames[_depositorAddress] >= depositFrame;
    }
}