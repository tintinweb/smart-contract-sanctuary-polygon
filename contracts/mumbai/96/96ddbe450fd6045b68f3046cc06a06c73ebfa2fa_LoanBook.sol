pragma solidity 0.8.13;

import "./ILoanBook.sol";
import "../token/IDSToken.sol";
import "../registry/IDSRegistryService.sol";
import "../trust/IDSTrustService.sol";
import "../utils/SecuritizeConstants.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

//SPDX-License-Identifier: UNLICENSED
contract LoanBook is ILoanBook, SecuritizeConstants, UUPSUpgradeable, PausableUpgradeable, AccessControlUpgradeable {

    uint256 constant MAX_INT = 2 ** 256 - 1;
    uint256 constant SECONDS_IN_ONE_YEAR = 31577600;
    uint256 constant PERCENTAGE_FACTOR = 1e4; // percentage plus two decimals

    mapping(string => uint256) public noncePerInvestor;
    bytes32 public DOMAIN_SEPARATOR;

    IDSToken public dsToken;
    IERC20Upgradeable public stableCoin;

    IDSRegistryService public registryService;
    IDSTrustService public trustService;

    mapping(bytes32 => DataTypes.Borrowing) public borrowings;
    mapping(bytes32 => DataTypes.Loan) public loans;
    mapping(uint256 => bytes32) public loanIds;

    mapping(address => mapping(uint256 => bytes32)) public borrowingsByBorrower;
    mapping(address => uint256) borrowingsByBorrowerCounter;

    uint256 public loansCount;

    bytes32 public constant LENDER_ROLE = keccak256("LENDER_ROLE");
    bool public onlyWhitelistedLenders;

    /**
     * @dev Modifier that checks that an account is Lender only if onlyWhitelistedLenders is true.
     * Reverts with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    modifier onlyLender() {
        if (onlyWhitelistedLenders) {
            _checkRole(LENDER_ROLE);
        }
        _;
    }

    /**
     * @dev Modifier that checks that the msg.sender
     * is the borrower of the borrow to be repaid
     * @param borrowingId The Borrow ID
     */
    modifier onlyBorrower(bytes32 borrowingId) {
        require(borrowings[borrowingId].borrower == msg.sender, "borrowing does not belong to sender");
        _;
    }

    /**
     * @dev Modifier that checks that Loan exists, revert otherwise
     * @param loanId Loan Identifier
     */
    modifier loanExists(bytes32 loanId) {
        require(loans[loanId].available, "loan not found");
        _;
    }

    /**
     * @dev Modifier that checks sender has issuer or master ROLE
     */
    modifier onlyIssuerOrAbove {
        uint8 role = trustService.getRole(msg.sender);
        require(role == ROLE_ISSUER || role == ROLE_MASTER, "insufficient trust level");
        _;
    }

    function initialize(
        address _masterAddress,
        address _dsToken,
        address _stableCoin,
        bool _onlyWhitelistedLenders
    ) public onlyProxy initializer override {
        dsToken = IDSToken(_dsToken);
        stableCoin = IERC20Upgradeable(_stableCoin);
        registryService = IDSRegistryService(dsToken.getDSService(DS_REGISTRY_SERVICE));
        trustService = IDSTrustService(dsToken.getDSService(DS_TRUST_SERVICE));
        onlyWhitelistedLenders = _onlyWhitelistedLenders;
        dsToken.approve(_masterAddress, MAX_INT);
        stableCoin.approve(_masterAddress, MAX_INT);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                block.chainid,
                this,
                SALT
            )
        );

        __UUPSUpgradeable_init();
        __Pausable_init();
        __AccessControl_init();

        // Grant the _masterAddress the default admin role: it will be able
        // to grant and revoke any roles
        // _grantRole only be call in initialize method
        _grantRole(DEFAULT_ADMIN_ROLE, _masterAddress);
    }

    function getVersion() external pure returns (uint8) {
        return 1;
    }

    /**
     * @dev required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addLoan(
        uint256 apy,
        uint256 amount,
        uint256 collateralAmount,
        uint256 period,
        bool isDsTokenLoan
    ) external override onlyLender whenNotPaused returns (bytes32) {
        string memory investor = registryService.getInvestor(msg.sender);
        require(!CommonUtils.isEmptyString(investor), 'lender must be investor');
        return _addLoan(apy, amount, collateralAmount, period, isDsTokenLoan);
    }

    function borrowingDetail(bytes32 borrowingId) public view returns (DataTypes.Borrowing memory) {
        require(borrowings[borrowingId].available, "borrowing id not found");
        return borrowings[borrowingId];
    }

    function getBorrowingDetailByIndex(address borrower, uint256 index) external view returns (DataTypes.Borrowing memory) {
        bytes32 borrowingId = borrowingsByBorrower[borrower][index];
        return borrowingDetail(borrowingId);
    }

    function borrowingCount(address borrower) external view returns (uint256) {
        return borrowingsByBorrowerCounter[borrower];
    }

    function loanDetail(bytes32 loanId) external view loanExists(loanId) returns (DataTypes.Loan memory) {
        return loans[loanId];
    }

    function removeLoan(bytes32 loanId) external onlyLender whenNotPaused loanExists(loanId) {
        _removeLoan(loanId);
    }

    function borrowAndRegisterInvestor(
        bytes32 loanId,
        uint256 amount,
        string memory legalContractHash,
        string memory investorId,
        address investorWallet,
        string memory investorCountry,
        uint8[] memory investorAttributeIds,
        uint256[] memory investorAttributeValues,
        uint256[] memory investorAttributeExpirations,
        uint256 blockLimit
    ) external whenNotPaused onlyIssuerOrAbove loanExists(loanId) {
        require(tx.origin == investorWallet, "wallet does not belong to signer");
        require(blockLimit >= block.number, "transaction too old");

        //Investor does not exist
        if (!registryService.isInvestor(investorId)) {
            _registerNewInvestor(
                investorId,
                investorCountry,
                investorAttributeIds,
                investorAttributeValues,
                investorAttributeExpirations
            );
        }

        //Check if new wallet should be added
        string memory investorWithNewWallet = registryService.getInvestor(investorWallet);
        if (CommonUtils.isEmptyString(investorWithNewWallet)) {
            registryService.addWallet(investorWallet, investorId);
        }
        else {
            require(CommonUtils.isEqualString(investorId, investorWithNewWallet), "wallet does not belong to investor");
        }

        borrow(loanId, amount, legalContractHash, investorWallet);
    }

    function executePreApprovedTransaction(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        string memory investorId,
        address destination,
        address executor,
        bytes memory data,
        uint256[] memory params
    ) external override whenNotPaused {
        require(params.length == 2, "incorrect params length");

        bytes32 txInputHash = keccak256(
            abi.encode(
                TXTYPE_HASH,
                destination,
                params[0],
                keccak256(data),
                noncePerInvestor[investorId],
                executor,
                params[1],
                keccak256(abi.encodePacked(investorId))
            )
        );

        bytes32 totalHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash)
        );

        address recovered = ecrecover(totalHash, sigV, sigR, sigS);
        // Check that the recovered address is an issuer
        uint256 signerRole = trustService.getRole(recovered);
        require(signerRole == ROLE_ISSUER || signerRole == ROLE_MASTER, "invalid signature");

        noncePerInvestor[investorId]++;

        // Execute encoded transaction data
        uint256 value = params[0];
        uint256 gasLimit = params[1];
        assembly {
            let ptr := add(data, 0x20)
            let result := call(gasLimit, destination, value, ptr, mload(data), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return (ptr, size)
            }
        }
    }

    function borrow(
        bytes32 loanId,
        uint256 amount,
        string memory legalContractHash,
        address investorWallet
    ) public whenNotPaused loanExists(loanId) {
        DataTypes.Loan storage loan = loans[loanId];
        require(loan.status == DataTypes.LoanStatus.Open, "loan is not open");
        require(amount <= loan.balance, "insufficient loan remaining balance");

        loan.borrowingCount++;
        loan.balance -= amount;
        loan.updateTime = block.timestamp;

        if (loan.balance == 0) {
            loan.status = DataTypes.LoanStatus.Done;
        }

        uint256 collateralAmount = amount * loan.collateralAmount / loan.amount;

        bytes32 borrowingHash = keccak256(abi.encodePacked(
                loanId,
                loan.borrowingCount,
                legalContractHash,
                msg.sender,
                block.number,
                amount
            ));

        borrowings[borrowingHash] = DataTypes.Borrowing(
            borrowingHash,
            msg.sender,
            loanId,
            amount,
            collateralAmount,
            DataTypes.BorrowingStatus.InProgress,
            block.timestamp,
            0,
            true
        );
        borrowingsByBorrower[investorWallet][borrowingsByBorrowerCounter[investorWallet]] = borrowingHash;
        borrowingsByBorrowerCounter[msg.sender]++;
        // swap tokens
        if (loan.isDsTokenLoan) {
            dsToken.transfer(investorWallet, amount);
            stableCoin.transferFrom(investorWallet, address(this), collateralAmount);
        } else {
            stableCoin.transferFrom(loan.lender, investorWallet, amount);
            dsToken.transferFrom(investorWallet, address(this), collateralAmount);
        }

        emit Borrow(investorWallet, loan.lender, loan.loanId, borrowingHash, amount, collateralAmount, loan.apy, loan.period, legalContractHash, loan.isDsTokenLoan);
    }

    function repay(bytes32 borrowingId) external whenNotPaused onlyBorrower(borrowingId) {
        DataTypes.Borrowing storage borrowing = borrowings[borrowingId];
        require(borrowing.status == DataTypes.BorrowingStatus.InProgress, "borrowing is not in progress");
        DataTypes.Loan memory loan = loans[borrowing.loanId];

        borrowing.status = DataTypes.BorrowingStatus.Repaid;
        borrowing.updateTime = block.timestamp;

        // Borrowing time duration in seconds
        uint256 borrowingTime = block.timestamp - borrowing.creationTime;

        uint256 annualInterest;
        uint256 borrowingInterest;
        uint256 paybackAmount;

        // transfer tokens
        if (loan.isDsTokenLoan) {
            // Percentages are defined by default with 2 decimals of precision (100.00)
            annualInterest = borrowing.collateralAmount * loan.apy / PERCENTAGE_FACTOR;
            borrowingInterest = borrowingTime * annualInterest / SECONDS_IN_ONE_YEAR;

            if (borrowingInterest > borrowing.collateralAmount) {
                paybackAmount = 0;
                borrowingInterest = borrowing.collateralAmount;
            } else {
                paybackAmount = borrowing.collateralAmount - borrowingInterest;
            }

            stableCoin.transfer(msg.sender, paybackAmount);
            stableCoin.transfer(loan.lender, borrowingInterest);
            dsToken.transferFrom(msg.sender, loan.lender, borrowing.amount);
        } else {
            // Percentages are defined by default with 2 decimals of precision (100.00)
            annualInterest = borrowing.amount * loan.apy / PERCENTAGE_FACTOR;
            borrowingInterest = borrowingTime * annualInterest / SECONDS_IN_ONE_YEAR;

            paybackAmount = borrowing.collateralAmount;

            dsToken.transfer(msg.sender, paybackAmount);
            stableCoin.transferFrom(msg.sender, loan.lender, borrowingInterest + borrowing.amount);
        }

        emit Repay(borrowing.borrower, loan.lender, loan.loanId, borrowing.borrowingId, borrowing.amount, borrowing.collateralAmount, paybackAmount, borrowingInterest);
    }

    function claimCollateral(bytes32 borrowingId) external whenNotPaused onlyLender {
        DataTypes.Borrowing storage borrowing = borrowings[borrowingId];
        require(borrowing.status == DataTypes.BorrowingStatus.InProgress, "borrowing is not in progress");
        uint256 borrowingTime = block.timestamp - borrowing.creationTime;
        DataTypes.Loan memory loan = loans[borrowing.loanId];
        require(borrowingTime > loan.period, "borrowing has not expired yet");
        require(loan.lender == msg.sender, "loan does not belong to lender");

        borrowing.status = DataTypes.BorrowingStatus.Claimed;
        borrowing.updateTime = block.timestamp;

        // transfer tokens
        if (loan.isDsTokenLoan) {
            stableCoin.transfer(msg.sender, borrowing.collateralAmount);
        } else {
            dsToken.transfer(msg.sender, borrowing.collateralAmount);
        }

        emit ClaimCollateral(borrowing.borrower, loan.lender, loan.loanId, borrowing.borrowingId, borrowing.amount, borrowing.collateralAmount);
    }

    function getLoanByIndex(uint256 loanIndex) external view returns (DataTypes.Loan memory) {
        require(loanIndex <= loansCount, "loan index not found");
        return loans[loanIds[loanIndex]];
    }

    function addLender(address lender) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(LENDER_ROLE, lender);
    }

    function setOnlyWhitelistedLenders(bool _onlyWhitelistedLenders) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        onlyWhitelistedLenders = _onlyWhitelistedLenders;
    }

    function getDsToken() external view returns (address) {
        return address(dsToken);
    }

    function getStableCoin() external view returns (address) {
        return address(stableCoin);
    }

    function _addLoan(
        uint256 apy,
        uint256 amount,
        uint256 collateralAmount,
        uint256 period,
        bool isDsTokenLoan
    ) internal returns (bytes32) {
        require(apy > 0, 'apy can not be 0');
        require(amount > 0, 'amount can not be 0');
        require(collateralAmount > 0, 'collateral amount can not be 0');
        require(period > 0, 'period can not be 0');

        bytes32 loanHash = keccak256(abi.encodePacked(
                loansCount,
                msg.sender,
                block.number,
                apy,
                amount,
                collateralAmount,
                period,
                isDsTokenLoan
            ));

        loans[loanHash] = DataTypes.Loan(
            loanHash,
            msg.sender,
            amount,
            amount,
            apy,
            collateralAmount,
            period,
            DataTypes.LoanStatus.Open,
            isDsTokenLoan,
            true,
            0,
            block.timestamp,
            0
        );

        loanIds[loansCount] = loanHash;
        loansCount++;

        if (isDsTokenLoan) {
            require(amount <= dsToken.balanceOf(address(msg.sender)), 'not enough balance');
            dsToken.transferFrom(msg.sender, address(this), amount);
        }

        emit AddLoan(msg.sender, loanHash, amount, collateralAmount, apy, period, isDsTokenLoan);
        return loanHash;
    }

    function _removeLoan(bytes32 loanId) internal {
        DataTypes.Loan storage loan = loans[loanId];
        require(loan.status == DataTypes.LoanStatus.Open, "loan is not open");
        require(loan.lender == msg.sender, "loan does not belong to lender");
        if (loan.borrowingCount == 0) {
            loan.status = DataTypes.LoanStatus.Canceled;
        } else {
            loan.status = DataTypes.LoanStatus.PartiallyCanceled;
        }

        if (loan.isDsTokenLoan) {
            dsToken.transfer(loan.lender, loan.balance);
        }

        emit RemoveLoan(loan.lender, loanId, loan.amount, loan.status);
    }

    function _registerNewInvestor(
        string memory _senderInvestorId,
        string memory _investorCountry,
        uint8[] memory _investorAttributeIds,
        uint256[] memory _investorAttributeValues,
        uint256[] memory _investorAttributeExpirations
    ) private {
        require(_investorAttributeIds.length == _investorAttributeValues.length &&
            _investorAttributeValues.length == _investorAttributeExpirations.length,
            "investor params incorrect length"
        );
        registryService.registerInvestor(_senderInvestorId, "");
        registryService.setCountry(_senderInvestorId, _investorCountry);
        for (uint256 i = 0; i < _investorAttributeIds.length; i++) {
            registryService.setAttribute(
                _senderInvestorId,
                _investorAttributeIds[i],
                _investorAttributeValues[i],
                _investorAttributeExpirations[i],
                "");
        }
    }
}

pragma solidity 0.8.13;

//SPDX-License-Identifier: UNLICENSED
abstract contract SecuritizeConstants {
    // Trust service constantes
    uint8 public constant ROLE_MASTER = 1;
    uint8 public constant ROLE_ISSUER = 2;

    //RegistryService constants
    uint8 public constant NONE = 0;
    uint8 public constant KYC_APPROVED = 1;
    uint8 public constant ACCREDITED = 2;
    uint8 public constant QUALIFIED = 4;
    uint8 public constant PROFESSIONAL = 8;

    uint8 public constant PENDING = 0;
    uint8 public constant APPROVED = 1;
    uint8 public constant REJECTED = 2;
    uint8 public constant EXCHANGE = 4;

    uint256 public constant DS_TRUST_SERVICE = 1;
    uint256 public constant DS_REGISTRY_SERVICE = 4;

    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name, string version, uint256 chainId, address verifyingContract, bytes32 salt)")
    bytes32 constant EIP712_DOMAIN_TYPE_HASH = 0x3696d4b0e5e87469c3902d2bb91ad254543a43933b818534ff7fe9a6a137d4d3;

    // keccak256("LoanBook")
    bytes32 constant NAME_HASH = 0x4b135c29ccfe6976266b578e04ffc23ef7c9954430712d625016691d0b42dd5f;

    // keccak256("executePreApprovedTransaction(string memory investorId, address destination, address executor, bytes data, uint256[] memory params)")
    bytes32 constant TXTYPE_HASH = 0x930a292ce3e2efb784ade744e679c45677e0f9673550cce5488eca13bb1b5a86;

    //keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    bytes32 constant SALT = 0xc7c09cf61ec4558aac49f42b32ffbafd87af4676341e61db3c383153955f6f39;
}

pragma solidity 0.8.13;

//SPDX-License-Identifier: UNLICENSED
library CommonUtils {
  enum IncDec { Increase, Decrease }

  function encodeString(string memory _str) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_str));
  }

  function isEqualString(string memory _str1, string memory _str2) internal pure returns (bool) {
    return encodeString(_str1) == encodeString(_str2);
  }

  function isEmptyString(string memory _str) internal pure returns (bool) {
    return isEqualString(_str, "");
  }
}

pragma solidity 0.8.13;

/**
 * @title IDSTrustService
 * @dev An interface for a trust service which allows role-based access control for other contracts.
 */
//SPDX-License-Identifier: UNLICENSED
interface IDSTrustService {
    /**
     * @dev Transfers the ownership (MASTER role) of the contract.
     * @param _address The address which the ownership needs to be transferred to.
     * @return A boolean that indicates if the operation was successful.
     */
    function setServiceOwner(
        address _address /*onlyMaster*/
    ) external returns (bool);

    /**
     * @dev Sets a role for a wallet.
     * @dev Should not be used for setting MASTER (use setServiceOwner) or role removal (use removeRole).
     * @param _address The wallet whose role needs to be set.
     * @param _role The role to be set.
     * @return A boolean that indicates if the operation was successful.
     */
    function setRole(
        address _address,
        uint8 _role /*onlyMasterOrIssuer*/
    ) external returns (bool);

    /**
     * @dev Removes the role for a wallet.
     * @dev Should not be used to remove MASTER (use setServiceOwner).
     * @param _address The wallet whose role needs to be removed.
     * @return A boolean that indicates if the operation was successful.
     */
    function removeRole(
        address _address /*onlyMasterOrIssuer*/
    ) external returns (bool);

    /**
     * @dev Gets the role for a wallet.
     * @param _address The wallet whose role needs to be fetched.
     * @return A boolean that indicates if the operation was successful.
     */
    function getRole(address _address) external view returns (uint8);

    function addEntity(
        string memory _name,
        address _owner /*onlyMasterOrIssuer onlyNewEntity onlyNewEntityOwner*/
    ) external;

    function changeEntityOwner(
        string memory _name,
        address _oldOwner,
        address _newOwner /*onlyMasterOrIssuer onlyExistingEntityOwner*/
    ) external;

    function addOperator(
        string memory _name,
        address _operator /*onlyEntityOwnerOrAbove onlyNewOperator*/
    ) external;

    function removeOperator(
        string memory _name,
        address _operator /*onlyEntityOwnerOrAbove onlyExistingOperator*/
    ) external;

    function addResource(
        string memory _name,
        address _resource /*onlyMasterOrIssuer onlyExistingEntity onlyNewResource*/
    ) external;

    function removeResource(
        string memory _name,
        address _resource /*onlyMasterOrIssuer onlyExistingResource*/
    ) external;

    function getEntityByOwner(address _owner) external view returns (string memory);

    function getEntityByOperator(address _operator) external view returns (string memory);

    function getEntityByResource(address _resource) external view returns (string memory);

    function isResourceOwner(address _resource, address _owner) external view returns (bool);

    function isResourceOperator(address _resource, address _operator) external view returns (bool);
}

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../utils/CommonUtils.sol";
import "../omnibus/IDSOmnibusWalletController.sol";

//SPDX-License-Identifier: UNLICENSED
interface IDSToken is IERC20Upgradeable {
    function getDSService(uint256 _serviceId) external view returns (address);
    /**
     * @dev Sets the total issuance cap
     * Note: The cap is compared to the total number of issued token, not the total number of tokens available,
     * So if a token is burned, it is not removed from the "total number of issued".
     * This call cannot be called again after it was called once.
     * @param _cap address The address which is going to receive the newly issued tokens
     */
    function setCap(
        uint256 _cap /*onlyMaster*/
    ) external;

    /******************************
       TOKEN ISSUANCE (MINTING)
   *******************************/

    /**
     * @dev Issues unlocked tokens
     * @param _to address The address which is going to receive the newly issued tokens
     * @param _value uint256 the value of tokens to issue
     * @return true if successful
     */
    function issueTokens(
        address _to,
        uint256 _value /*onlyIssuerOrAbove*/
    ) external returns (bool);

    /**
     * @dev Issuing tokens from the fund
     * @param _to address The address which is going to receive the newly issued tokens
     * @param _value uint256 the value of tokens to issue
     * @param _valueLocked uint256 value of tokens, from those issued, to lock immediately.
     * @param _reason reason for token locking
     * @param _releaseTime timestamp to release the lock (or 0 for locks which can only released by an unlockTokens call)
     * @return true if successful
     */
    function issueTokensCustom(
        address _to,
        uint256 _value,
        uint256 _issuanceTime,
        uint256 _valueLocked,
        string memory _reason,
        uint64 _releaseTime /*onlyIssuerOrAbove*/
    ) external returns (bool);

    function issueTokensWithMultipleLocks(
        address _to,
        uint256 _value,
        uint256 _issuanceTime,
        uint256[] memory _valuesLocked,
        string memory _reason,
        uint64[] memory _releaseTimes /*onlyIssuerOrAbove*/
    ) external returns (bool);

    //*********************
    // TOKEN BURNING
    //*********************

    function burn(
        address _who,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    function omnibusBurn(
        address _omnibusWallet,
        address _who,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    //*********************
    // TOKEN SIEZING
    //*********************

    function seize(
        address _from,
        address _to,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    function omnibusSeize(
        address _omnibusWallet,
        address _from,
        address _to,
        uint256 _value,
        string memory _reason
        /*onlyIssuerOrAbove*/
    ) external;

    //*********************
    // WALLET ENUMERATION
    //*********************

    function getWalletAt(uint256 _index) external view returns (address);

    function walletCount() external view returns (uint256);

    //**************************************
    // MISCELLANEOUS FUNCTIONS
    //**************************************
    function isPaused() external view returns (bool);

    function balanceOfInvestor(string memory _id) external view returns (uint256);

    function updateOmnibusInvestorBalance(
        address _omnibusWallet,
        address _wallet,
        uint256 _value,
        CommonUtils.IncDec _increase /*onlyOmnibusWalletController*/
    ) external returns (bool);

    function emitOmnibusTransferEvent(
        address _omnibusWallet,
        address _from,
        address _to,
        uint256 _value /*onlyOmnibusWalletController*/
    ) external;

    function emitOmnibusTBEEvent(address omnibusWallet, int256 totalDelta, int256 accreditedDelta,
        int256 usAccreditedDelta, int256 usTotalDelta, int256 jpTotalDelta /*onlyTBEOmnibus*/
    ) external;

    function emitOmnibusTBETransferEvent(address omnibusWallet, string memory externalId) external;

    function preTransferCheck(address _from, address _to, uint256 _value) external view returns (uint256 code, string memory reason);
}

pragma solidity 0.8.13;

import "../utils/CommonUtils.sol";
import "../omnibus/IDSOmnibusWalletController.sol";

//SPDX-License-Identifier: UNLICENSED
interface IDSRegistryService {

    function registerInvestor(
        string memory _id,
        string memory _collision_hash /*onlyExchangeOrAbove newInvestor(_id)*/
    ) external returns (bool);

    function updateInvestor(
        string memory _id,
        string memory _collisionHash,
        string memory _country,
        address[] memory _wallets,
        uint8[] memory _attributeIds,
        uint256[] memory _attributeValues,
        uint256[] memory _attributeExpirations /*onlyIssuerOrAbove*/
    ) external returns (bool);

    function removeInvestor(
        string memory _id /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function setCountry(
        string memory _id,
        string memory _country /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function getCountry(string memory _id) external view returns (string memory);

    function getCollisionHash(string memory _id) external view returns (string memory);

    function setAttribute(
        string memory _id,
        uint8 _attributeId,
        uint256 _value,
        uint256 _expiry,
        string memory _proofHash /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function getAttributeValue(string memory _id, uint8 _attributeId) external view returns (uint256);

    function getAttributeExpiry(string memory _id, uint8 _attributeId) external view returns (uint256);

    function getAttributeProofHash(string memory _id, uint8 _attributeId) external view returns (string memory);

    function addWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove newWallet(_address)*/
    ) external returns (bool);

    function removeWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove walletExists walletBelongsToInvestor(_address, _id)*/
    ) external returns (bool);

    function addOmnibusWallet(
        string memory _id,
        address _omnibusWallet,
        IDSOmnibusWalletController _omnibusWalletController /*onlyIssuerOrAbove newOmnibusWallet*/
    ) external;

    function removeOmnibusWallet(
        string memory _id,
        address _omnibusWallet /*onlyIssuerOrAbove omnibusWalletControllerExists*/
    ) external;

    function getOmnibusWalletController(address _omnibusWallet) external view returns (IDSOmnibusWalletController);

    function isOmnibusWallet(address _omnibusWallet) external view returns (bool);

    function getInvestor(address _address) external view returns (string memory);

    function getInvestorDetails(address _address) external view returns (string memory, string memory);

    function getInvestorDetailsFull(string memory _id)
        external
        view
        returns (string memory, uint256[] memory, uint256[] memory, string memory, string memory, string memory, string memory);

    function isInvestor(string memory _id) external view returns (bool);

    function isWallet(address _address) external view returns (bool);

    function isAccreditedInvestor(string calldata _id) external view returns (bool);

    function isQualifiedInvestor(string calldata _id) external view returns (bool);

    function isAccreditedInvestor(address _wallet) external view returns (bool);

    function isQualifiedInvestor(address _wallet) external view returns (bool);

    function getInvestors(address _from, address _to) external view returns (string memory, string memory);
}

pragma solidity 0.8.13;

import "./DataTypes.sol";

//SPDX-License-Identifier: UNLICENSED
interface ILoanBook {

    event Borrow(
        address indexed borrower,
        address indexed lender,
        bytes32 loanId,
        bytes32 borrowingId,
        uint256 amount,
        uint256 collateralAmount,
        uint256 apy,
        uint256 period,
        string legalContractHash,
        bool isDsTokenLoan
    );

    event AddLoan(
        address indexed lender,
        bytes32 loanId,
        uint256 amount,
        uint256 collateralAmount,
        uint256 apy,
        uint256 period,
        bool isDsTokenLoan
    );

    event RemoveLoan(
        address indexed lender,
        bytes32 loanId,
        uint256 amountReturned,
        DataTypes.LoanStatus status
    );

    event Repay(
        address indexed borrower,
        address indexed lender,
        bytes32 loanId,
        bytes32 borrowId,
        uint256 amount,
        uint256 collateralAmount,
        uint256 paybackAmount,
        uint256 interest
    );

    event ClaimCollateral(
        address indexed borrower,
        address indexed lender,
        bytes32 loanId,
        bytes32 borrowId,
        uint256 amount,
        uint256 collateralAmount
    );

    /**
     * @dev Function wo be invoked by the proxy contract when the LoanBook is deployed.
     * @param masterAddress The address with administrative powers
     * @param dsToken The address of the DSToken configured in this contract instance
     * @param stableCoin The address of the stable coin configured in this contract instance
     * @param _onlyWhitelistedLenders Flag to limit loans to whitelisted lenders
    **/
    function initialize(address masterAddress, address dsToken, address stableCoin, bool _onlyWhitelistedLenders) external;

    /**
     * @dev Get the contract version
     * @return Contract version
    **/
    function getVersion() external pure returns (uint8);

    /**
     * @dev Get the DSProtocol token address
     * @return dsTokenAddress
    **/
    function getDsToken() external view returns (address);

    /**
    * @dev Get the StableCoin token address
    * @return stableCoinAddress
    **/
    function getStableCoin() external view returns (address);

    /**
     * @dev Post a Loan to be offered to borrowers
     * @param apy Annual Percentage Yield of this Loan
     * @param amount Amount of tokens to be lent
     * @param collateralAmount Amount of tokens to be used as collateral
     * @param period Loan duration in seconds
     * @param isDsTokenLoan If true, the lent amount will be IDSToken and the collateral amount will be an Stable Coin
     * @return loanId
    **/
    function addLoan(
        uint256 apy,
        uint256 amount,
        uint256 collateralAmount,
        uint256 period,
        bool isDsTokenLoan
    ) external returns (bytes32);


    /**
     * @dev Remove a Loan in Open status and returns tokens to lender.
     * @param loanId The Loan ID to be removed by the lender
    **/
    function removeLoan(bytes32 loanId) external; // only lender

    /**
     * @dev Validates off-chain signatures and executes transaction.
     * @param sigV V signature
     * @param sigR R signature
     * @param sigR R signature
     * @param investorId Investor blockchain ID
     * @param destination address
     * @param data encoded transaction data.
     * @param params array of params. params[0] = value, params[1] = gasLimit
     */
    function executePreApprovedTransaction(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        string memory investorId,
        address destination,
        address executor,
        bytes memory data,
        uint256[] memory params
    ) external;

    /**
     * @dev Borrow a Loan and register investor
     * @param loanId The Loan ID to be borrowed
     * @param amount The amount to be borrowed
     * @param legalContractHash Hash that represents a legal contract between the lender and the borrower
     * @param investorId The investor blockchain ID
     * @param investorWallet Investor wallet to be registered
     * @param investorCountry Investor country
     * @param investorAttributeIds Investor attributes IDs
     * @param investorAttributeValues Investor attributes values
     * @param investorAttributeExpirations Investor attributes expirations
     * @param blockLimit Max block number to transaction can be executed
    **/
    function borrowAndRegisterInvestor(
        bytes32 loanId,
        uint256 amount,
        string memory legalContractHash,
        string memory investorId,
        address investorWallet,
        string memory investorCountry,
        uint8[] memory investorAttributeIds,
        uint256[] memory investorAttributeValues,
        uint256[] memory investorAttributeExpirations,
        uint256 blockLimit
    ) external;

    /**
     * @dev Borrow a Loan
     * @param loanId The Loan ID to be borrowed
     * @param amount The amount to be borrowed
     * @param legalContractHash Hash that represents a legal contract between the lender and the borrower
     * @param investorWallet Investor wallet to be registered
    **/
    function borrow(
        bytes32 loanId,
        uint256 amount,
        string memory legalContractHash,
        address investorWallet
    ) external;

     /**
     * @dev Get a loan by ID
     * @param loanId The Loan ID to be retrieved
     * @return Loan
    **/
    function loanDetail(bytes32 loanId) external view returns (DataTypes.Loan memory);

    /**
     * @dev Return the detail of an specific borrowing
     * @param borrowingId Id
     * @return borrowing
    **/
    function borrowingDetail(bytes32 borrowingId) external view returns (DataTypes.Borrowing memory);

    /**
    * @dev Get a loan by index
    * @param loanIndex starting from 0
    * @return Loan
    **/
    function getLoanByIndex(uint256 loanIndex) external view returns (DataTypes.Loan memory);

    /**
     * @dev Repay a borrowing
     * @param borrowingId The Borrowing ID to be repaid
    **/
    function repay(bytes32 borrowingId) external;

    /**
     * @dev Invoked by lenders to claim collateral of borrowings
     * @param borrowingId The Borrowing ID to be claimed
    **/
    function claimCollateral(bytes32 borrowingId) external;

    /**
     * @dev Add a lender to the LoanBook
     * @param lender The lender address
     **/
    function addLender(address lender) external;

    /**
     * @dev Set the only whitelisted lender flag, if true,
     * only those whitelisted addresses will be able to add loans
     * @param onlyWhitelistedLenders flag
     **/
    function setOnlyWhitelistedLenders(bool onlyWhitelistedLenders) external;

    /**
     * @dev Get the count of loans in this book
     * @return loans count
     **/
    function loansCount() external view returns (uint256);

    /**
     * @dev Return the number of borrowing taken by a borrower
     * @param borrower address
     * @return the number of borrowing
    **/
    function borrowingCount(address borrower) external view returns (uint256);

    /**
     * @dev Return the detail of an specific borrowing
     * @param borrower address
     * @param index to be returned starting from 0
     * @return borrowing
    **/
    function getBorrowingDetailByIndex(address borrower, uint256 index) external view returns (DataTypes.Borrowing memory);
}

pragma solidity 0.8.13;

//SPDX-License-Identifier: UNLICENSED
library DataTypes {
    enum LoanStatus { Open, PartiallyCanceled, Canceled, Done }
    enum BorrowingStatus { InProgress, Repaid, Claimed }

    struct Borrowing {
        bytes32 borrowingId;
        address borrower;
        bytes32 loanId;
        uint256 amount; // <= LoanOffer.amount
        uint256 collateralAmount;
        BorrowingStatus status;
        uint256 creationTime; //Creation timestamp
        uint256 updateTime;
        bool available;
    }

    struct Loan {
        bytes32 loanId;
        address lender;
        uint256 amount;
        uint256 balance;
        uint256 apy;
        uint256 collateralAmount;
        uint256 period; //Period in seconds
        LoanStatus status;
        bool isDsTokenLoan;
        bool available;
        uint256 borrowingCount;
        uint256 creationTime;
        uint256 updateTime;
    }
}

pragma solidity 0.8.13;


//SPDX-License-Identifier: UNLICENSED
interface IDSOmnibusWalletController {
    function setAssetTrackingMode(uint8 _assetTrackingMode) external;

    function getAssetTrackingMode() external view returns (uint8);

    function isHolderOfRecord() external view returns (bool);

    function balanceOf(address _who) external view returns (uint256);

    function transfer(
        address _from,
        address _to,
        uint256 _value /*onlyOperator*/
    ) external;

    function deposit(
        address _to,
        uint256 _value /*onlyToken*/
    ) external;

    function withdraw(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;

    function seize(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;

    function burn(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}