pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

// import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ExternalStorage.sol";

/**
 * @dev Registry Contract module.
 *
 * This module is used to create instance of the Receipt registration contract.
 */
contract Agreement is ExternalStorage {
    constructor(
        address _VTAddr,
        bytes32 _CompanyNameVT,
        bytes32 _PhoneVT,
        bytes32 _AddressVT,
        bytes32 _EmailVT,
        bytes32 _BankNameVT,
        bytes32 _AccountNameVT,
        bytes32 _AccountNoVT,
        bytes32 _BankSwiftCodeVT
    ) public {
        vtDetails.VTAddr = _VTAddr;
        vtDetails.CompanyNameVT = _CompanyNameVT;
        vtDetails.PhoneVT = _PhoneVT;
        vtDetails.AddressVT = _AddressVT;
        vtDetails.EmailVT = _EmailVT;
        vtDetails.BankNameVT = _BankNameVT;
        vtDetails.AccountNameVT = _AccountNameVT;
        vtDetails.AccountNoVT = _AccountNoVT;
        vtDetails.BankSwiftCodeVT = _BankSwiftCodeVT;
    }

    //  *************    SETTERS    *************

    function SaveAgreementSeller(
        address _SellerAddr,
        bytes32 _NameSeller,
        bytes32 _PhoneSeller,
        bytes32 _AddressSeller,
        bytes32 _CompanySeller,
        bytes32 _EmailSeller,
        bytes32 _BankNameSeller,
        bytes32 _AccountNameSeller,
        bytes32 _AccountNoSeller,
        bytes32 _BankSwiftCodeSeller
    ) public returns (bool) {
        sellerDetails.SellerAddr = _SellerAddr;
        sellerDetails.NameSeller = _NameSeller;
        sellerDetails.PhoneSeller = _PhoneSeller;
        sellerDetails.AddressSeller = _AddressSeller;
        sellerDetails.CompanySeller = _CompanySeller;
        sellerDetails.EmailSeller = _EmailSeller;

        sellerDetails.BankNameSeller = _BankNameSeller;
        sellerDetails.AccountNameSeller = _AccountNameSeller;
        sellerDetails.AccountNoSeller = _AccountNoSeller;
        sellerDetails.BankSwiftCodeSeller = _BankSwiftCodeSeller;

        return true;
    }

    function SaveAgreementBuyer(
        address _BuyerAddr,
        bytes32 _NameBuyer,
        bytes32 _PhoneBuyer,
        bytes32 _AddressBuyer,
        bytes32 _CompanyBuyer,
        bytes32 _EmailBuyer,
        bytes32 _BankNameBuyer,
        bytes32 _AccountNameBuyer,
        bytes32 _AccountNoBuyer,
        bytes32 _BankSwiftCodeBuyer
    ) public returns (bool) {
        buyerDetails.BuyerAddr = _BuyerAddr;
        buyerDetails.NameBuyer = _NameBuyer;
        buyerDetails.PhoneBuyer = _PhoneBuyer;
        buyerDetails.AddressBuyer = _AddressBuyer;
        buyerDetails.CompanyBuyer = _CompanyBuyer;
        buyerDetails.EmailBuyer = _EmailBuyer;

        buyerDetails.BankNameBuyer = _BankNameBuyer;
        buyerDetails.AccountNameBuyer = _AccountNameBuyer;
        buyerDetails.AccountNoBuyer = _AccountNoBuyer;
        buyerDetails.BankSwiftCodeBuyer = _BankSwiftCodeBuyer;

        return true;
    }

    function SaveAgreementAcOfficer(
        bytes32 _AccountOfficerNameVT,
        bytes32 _AccountOfficerNoVT,
        bytes32 _AccountOfficerEmailVT,
        bytes32 _AccountOfficerNameSeller,
        bytes32 _AccountOfficerNoSeller,
        bytes32 _AccountOfficerEmailSeller,
        bytes32 _AccountOfficerNameBuyer,
        bytes32 _AccountOfficerNoBuyer,
        bytes32 _AccountOfficerEmailBuyer
    ) public returns (bool) {
        acOfficerDetails.AccountOfficerNameVT = _AccountOfficerNameVT;
        acOfficerDetails.AccountOfficerNoVT = _AccountOfficerNoVT;
        acOfficerDetails.AccountOfficerEmailVT = _AccountOfficerEmailVT;

        acOfficerDetails.AccountOfficerNameSeller = _AccountOfficerNameSeller;
        acOfficerDetails.AccountOfficerNoSeller = _AccountOfficerNoSeller;
        acOfficerDetails.AccountOfficerEmailSeller = _AccountOfficerEmailSeller;

        acOfficerDetails.AccountOfficerNameBuyer = _AccountOfficerNameBuyer;
        acOfficerDetails.AccountOfficerNoBuyer = _AccountOfficerNoBuyer;
        acOfficerDetails.AccountOfficerEmailBuyer = _AccountOfficerEmailBuyer;
    }

    function SaveAgreementDetails(
        bytes32 _SellerIntermediaries,
        bytes32 _BuyerIntermediaries,
        bytes32 _VTPercentShare,
        bytes32 _SellerPercentShare,
        bytes32 _BuyerPercentShare
    ) public returns (bool) {
        agreementDetails.SellerIntermediaries = _SellerIntermediaries;
        agreementDetails.BuyerIntermediaries = _BuyerIntermediaries;
        agreementDetails.VTPercentShare = _VTPercentShare;
        agreementDetails.SellerPercentShare = _SellerPercentShare;
        agreementDetails.BuyerPercentShare = _BuyerPercentShare;

        return true;
    }

    // //  *************   GETTERS    **************

    function GetAgreement()
        public
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            vtDetails.VTAddr,
            vtDetails.CompanyNameVT,
            vtDetails.PhoneVT,
            vtDetails.AddressVT,
            vtDetails.EmailVT,
            vtDetails.BankNameVT,
            vtDetails.AccountNameVT,
            vtDetails.AccountNoVT,
            vtDetails.BankSwiftCodeVT
        );
    }

    function GetAgreementSeller()
        public
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            sellerDetails.SellerAddr,
            sellerDetails.NameSeller,
            sellerDetails.PhoneSeller,
            sellerDetails.AddressSeller,
            sellerDetails.CompanySeller,
            sellerDetails.EmailSeller,
            sellerDetails.BankNameSeller,
            sellerDetails.AccountNameSeller,
            sellerDetails.AccountNoSeller,
            sellerDetails.BankSwiftCodeSeller
        );
    }

    function GetAgreementBuyer()
        public
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            buyerDetails.BuyerAddr,
            buyerDetails.NameBuyer,
            buyerDetails.PhoneBuyer,
            buyerDetails.AddressBuyer,
            buyerDetails.CompanyBuyer,
            buyerDetails.EmailBuyer,
            buyerDetails.BankNameBuyer,
            buyerDetails.AccountNameBuyer,
            buyerDetails.AccountNoBuyer,
            buyerDetails.BankSwiftCodeBuyer
        );
    }

    function GetAgreementACO()
        public
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            acOfficerDetails.AccountOfficerNameVT,
            acOfficerDetails.AccountOfficerNoVT,
            acOfficerDetails.AccountOfficerEmailVT,
            acOfficerDetails.AccountOfficerNameSeller,
            acOfficerDetails.AccountOfficerNoSeller,
            acOfficerDetails.AccountOfficerEmailSeller,
            acOfficerDetails.AccountOfficerNameBuyer,
            acOfficerDetails.AccountOfficerNoBuyer,
            acOfficerDetails.AccountOfficerEmailBuyer
        );
    }

    function GetAgreementDetails()
        public
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            agreementDetails.SellerIntermediaries,
            agreementDetails.BuyerIntermediaries,
            agreementDetails.VTPercentShare,
            agreementDetails.SellerPercentShare,
            agreementDetails.BuyerPercentShare
        );
    }
}

pragma solidity ^0.5.0;

import "./Libs/SafeMath.sol";
import "./Ownable.sol";

/**
 * @dev Contract module which provides a basic storage system.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses created, owners of the contract and receipts record detailing land documentations.
 */
contract ExternalStorage {
    using SafeMath for uint256;

    address[] internal admins;
    address[] internal authorizers;
    address[] internal userList;
    address[] internal blackList;

    string internal constant SuperAdmin = "SuperAdmin";

    VTDetails internal vtDetails;
    SellerDetails internal sellerDetails;
    BuyerDetails internal buyerDetails;
    AcOfficerDetails internal acOfficerDetails;
    AgreementDetails internal agreementDetails;
    SPAContractData internal spacontractData;
    SPAContractDetails internal spacontractDetails;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isAuthorizer;
    mapping(address => bool) public isUserListed;
    mapping(address => bool) public isBlackListed;

    mapping(string => address) superAdmin;
    mapping(address => AdminDetails) Admins;

    //Events for UserManagement
    event AdminAdded(address indexed Admin);
    event AdminRemoved(address indexed Admin);
    event AuthorizerAdded(address indexed Authorizer);
    event AuthorizerRemoved(address indexed Authorizer);
    event SetUserListEvent(address indexed User);
    event RemovedUserList(address indexed User);
    event SetBlackListEvent(address indexed EvilUser);
    event RemoveUserBlackList(address indexed RedeemedUser);

    //Admin Details
    struct AdminDetails {
        address AdminID;
        bytes32 AdminName;
        address AddedBy;
    }

    //Structs for Agreement Contract
    struct VTDetails {
        address VTAddr;
        bytes32 CompanyNameVT;
        bytes32 PhoneVT;
        bytes32 AddressVT;
        bytes32 EmailVT;
        bytes32 BankNameVT;
        bytes32 AccountNameVT;
        bytes32 AccountNoVT;
        bytes32 BankSwiftCodeVT;
    }

    struct SellerDetails {
        address SellerAddr;
        bytes32 NameSeller;
        bytes32 PhoneSeller;
        bytes32 AddressSeller;
        bytes32 CompanySeller;
        bytes32 EmailSeller;
        bytes32 BankNameSeller;
        bytes32 AccountNameSeller;
        bytes32 AccountNoSeller;
        bytes32 BankSwiftCodeSeller;
    }

    struct BuyerDetails {
        address BuyerAddr;
        bytes32 NameBuyer;
        bytes32 PhoneBuyer;
        bytes32 AddressBuyer;
        bytes32 CompanyBuyer;
        bytes32 EmailBuyer;
        bytes32 BankNameBuyer;
        bytes32 AccountNameBuyer;
        bytes32 AccountNoBuyer;
        bytes32 BankSwiftCodeBuyer;
    }

    struct AcOfficerDetails {
        bytes32 AccountOfficerNameVT;
        bytes32 AccountOfficerNoVT;
        bytes32 AccountOfficerEmailVT;
        bytes32 AccountOfficerNameSeller;
        bytes32 AccountOfficerNoSeller;
        bytes32 AccountOfficerEmailSeller;
        bytes32 AccountOfficerNameBuyer;
        bytes32 AccountOfficerNoBuyer;
        bytes32 AccountOfficerEmailBuyer;
    }

    struct AgreementDetails {
        bytes32 SellerIntermediaries;
        bytes32 BuyerIntermediaries;
        bytes32 VTPercentShare;
        bytes32 SellerPercentShare;
        bytes32 BuyerPercentShare;
    }

    //SPA Contract Data
    struct SPAContractData {
        uint256 AssetID;
        bytes32 CommodityCode;
        bytes32 Standard;
        bytes32 Origin;
        bytes32 LoadingTerminal;
        bytes32 DeliveryDay;
        bytes32 Doc1;
        bytes32 Doc2;
        bytes32 Doc3;
    }

    //SPA Contract Details
    struct SPAContractDetails {
        bytes32 Packaging;
        bytes32 Quality;
        bytes32 Quantity;
        bytes32 BarrelPrice;
        bytes32 ContractLength;
        bytes32 Vessel;
        bytes32 IMONumber;
        bytes32 Procedure;
    }
}

pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./GetContractFactory.sol";

/**
 * @dev Contract module which provides a basic storage system.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses created, owners of the contract and land record detailing land documentations.
 */
contract Factory is Ownable, GetContractFactory{

    UserManagement private usermgt;

    //Events for Logic Contract
    event AgreementRegistered(
        address indexed VesselTrustAddr,
        Agreement indexed TokenizedAgreement
    );
    event SPARegistered(
        address indexed OwnerAddr,
        SPAContract indexed TokenizedSPAContract
    );
    event SPATransfered(address indexed NewOwner, uint256 AssetID);
    event BurntAsset(address indexed OwnerAddr, uint256 AssetID);



    function Initializable(address _usermgt) public initializer {
        usermgt = UserManagement(_usermgt);
    }

    function AgreementUtils(address _VTAddr, uint256 _Assetid)
        internal
        view
        returns (Agreement)
    {
        Agreement agreementContract = agreed[_VTAddr].assets[_Assetid];
        return agreementContract;
    }

    function SPAUtils(address _SellerAddr, uint256 _Assetid)
        internal
        view
        returns (SPAContract)
    {
        SPAContract spaContract = commodity[_SellerAddr].assets[_Assetid];
        return spaContract;
    }

    //     ***********   SETTERS   ************

    //  Register the Binding Agreement between the Seller, Buyer and VesselTrust
    function AgreementCreation(
        address _VTAddr,
        bytes32 _CompanyNameVT,
        bytes32 _PhoneVT,
        bytes32 _AddressVT,
        bytes32 _EmailVT,
        bytes32 _BankNameVT,
        bytes32 _AccountNameVT,
        bytes32 _AccountNoVT,
        bytes32 _BankSwiftCodeVT
    ) external returns (bool) {
        require(usermgt.IsAdmin(msg.sender), "Agreement: Not Admin");

        Agreement _agreementReg =
            new Agreement(
                _VTAddr,
                _CompanyNameVT,
                _PhoneVT,
                _AddressVT,
                _EmailVT,
                _BankNameVT,
                _AccountNameVT,
                _AccountNoVT,
                _BankSwiftCodeVT
            );

        agreed[_VTAddr].assets.push(_agreementReg);

        emit AgreementRegistered(_VTAddr, _agreementReg);

        return true;
    }

    //  Registration of the Agreement Details
    function AgreementSaveSeller(
        address _VTAddr,
        uint256 _Assetid,
        address _SellerAddr,
        bytes32 _NameSeller,
        bytes32 _PhoneSeller,
        bytes32 _AddressSeller,
        bytes32 _CompanySeller,
        bytes32 _EmailSeller,
        bytes32 _BankNameSeller,
        bytes32 _AccountNameSeller,
        bytes32 _AccountNoSeller,
        bytes32 _BankSwiftCodeSeller
    ) external returns (bool) {
        Agreement AContract = agreed[_VTAddr].assets[_Assetid];
        // Agreement AContract = AgreementUtils (_VTAddr, _Assetid);

        bool registered =
            AContract.SaveAgreementSeller(
                _SellerAddr,
                _NameSeller,
                _PhoneSeller,
                _AddressSeller,
                _CompanySeller,
                _EmailSeller,
                _BankNameSeller,
                _AccountNameSeller,
                _AccountNoSeller,
                _BankSwiftCodeSeller
            );

        return registered;
    }

    //  Registration of the Agreement Details
    function AgreementSaveBuyer(
        address _VTAddr,
        uint256 _Assetid,
        address _BuyerAddr,
        bytes32 _NameBuyer,
        bytes32 _PhoneBuyer,
        bytes32 _AddressBuyer,
        bytes32 _CompanyBuyer,
        bytes32 _EmailBuyer,
        bytes32 _BankNameBuyer,
        bytes32 _AccountNameBuyer,
        bytes32 _AccountNoBuyer,
        bytes32 _BankSwiftCodeBuyer
    ) external returns (bool) {
        // Agreement AContract = agreed[_VTAddr].assets[_Assetid];
        Agreement AContract = AgreementUtils(_VTAddr, _Assetid);

        bool registered =
            AContract.SaveAgreementBuyer(
                _BuyerAddr,
                _NameBuyer,
                _PhoneBuyer,
                _AddressBuyer,
                _CompanyBuyer,
                _EmailBuyer,
                _BankNameBuyer,
                _AccountNameBuyer,
                _AccountNoBuyer,
                _BankSwiftCodeBuyer
            );

        return registered;
    }

    function AgreementSaveACO(
        address _VTAddr,
        uint256 _Assetid,
        bytes32 _AccountOfficerNameVT,
        bytes32 _AccountOfficerNoVT,
        bytes32 _AccountOfficerEmailVT,
        bytes32 _AccountOfficerNameSeller,
        bytes32 _AccountOfficerNoSeller,
        bytes32 _AccountOfficerEmailSeller,
        bytes32 _AccountOfficerNameBuyer,
        bytes32 _AccountOfficerNoBuyer,
        bytes32 _AccountOfficerEmailBuyer
    ) external returns (bool) {
        Agreement AContract = AgreementUtils(_VTAddr, _Assetid);

        bool registered =
            AContract.SaveAgreementAcOfficer(
                _AccountOfficerNameVT,
                _AccountOfficerNoVT,
                _AccountOfficerEmailVT,
                _AccountOfficerNameSeller,
                _AccountOfficerNoSeller,
                _AccountOfficerEmailSeller,
                _AccountOfficerNameBuyer,
                _AccountOfficerNoBuyer,
                _AccountOfficerEmailBuyer
            );

        return registered;
    }

    function AgreementSaveDetails(
        address _VTAddr,
        uint256 _Assetid,
        bytes32 _SellerIntermediaries,
        bytes32 _BuyerIntermediaries,
        bytes32 _VTPercentShare,
        bytes32 _SellerPercentShare,
        bytes32 _BuyerPercentShare
    ) external returns (bool) {
        Agreement AContract = AgreementUtils(_VTAddr, _Assetid);

        bool registered =
            AContract.SaveAgreementDetails(
                _SellerIntermediaries,
                _BuyerIntermediaries,
                _VTPercentShare,
                _SellerPercentShare,
                _BuyerPercentShare
            );

        return registered;
    }

    //  Creating an SPA Contract by the Seller
    function SPAContractCreation(
        address _VTAddr,
        address _SellerAddr,
        address _BuyerAddr,
        address _agreementAddr
    ) external returns (bool) {
        require(
            msg.sender == _SellerAddr,
            "RContrant: Only Seller creates SPA"
        );
        require(usermgt.IsUserListed(_BuyerAddr), "RContrant: Register Buyer");
        require(!usermgt.IsBlackListed(_BuyerAddr), "RContrant: Buyer is BlackListed");
        require(
            _agreementAddr != address(0x0),
            "RContrant: No Agreement contract"
        );

        SPAContract _SPAReg =
            new SPAContract(_VTAddr, _SellerAddr, _BuyerAddr, _agreementAddr);

        commodity[_SellerAddr].assets.push(_SPAReg);

        emit SPARegistered(_SellerAddr, _SPAReg);

        return true;
    }

    function SPASaveData(
        address _SellerAddr,
        uint256 _Assetid,
        bytes32 _CommodityCode,
        bytes32 _Origin,
        bytes32 _LoadingTerminal,
        bytes32 _DeliveryDay
    ) external returns (bool) {
        require(msg.sender == _SellerAddr, "Only Seller can save SPA");

        SPAContract spaContract = SPAUtils(_SellerAddr, _Assetid);

        bool _SPAData =
            spaContract.SaveSPAContractData(
                _Assetid,
                _CommodityCode,
                _Origin,
                _LoadingTerminal,
                _DeliveryDay
            );

        return _SPAData;
    }

    function SPASaveDetails(
        address _SellerAddr,
        uint256 _Assetid,
        bytes32 _Standard,
        bytes32 _Packaging,
        bytes32 _Quality,
        bytes32 _Quantity,
        bytes32 _BarrelPrice,
        bytes32 _ContractLength,
        bytes32 _Vessel,
        bytes32 _IMONumber,
        bytes32 _Procedure
    ) external returns (bool) {
        require(msg.sender == _SellerAddr, "Only Seller can save SPA");

        SPAContract spaContract = SPAUtils(_SellerAddr, _Assetid);

        bool _SPAData =
            spaContract.SaveSPAContractDetails(
                _Standard,
                _Packaging,
                _Quality,
                _Quantity,
                _BarrelPrice,
                _ContractLength,
                _Vessel,
                _IMONumber,
                _Procedure
            );
        return _SPAData;
    }

    function SPASaveDoc(
        address _SellerAddr,
        uint256 _Assetid,
        bytes32 _NewDoc1,
        bytes32 _NewDoc2,
        bytes32 _NewDoc3
    ) external returns (bool) {
        require(msg.sender == _SellerAddr, "Only Seller can Save SPA");

        SPAContract spaContract = SPAUtils(_SellerAddr, _Assetid);

        bool _SPAData =
            spaContract.SaveSPAContractDoc(_NewDoc1, _NewDoc2, _NewDoc3);

        return _SPAData;
    }

    /**
     * to transfer Assets from owner to a user
     * @param _SellerAddr Owner of the tokenized SPA
     * @param _NewUserAddr Receiver of the tokenized SPA
     * @param _NewAssetid The New Asset ID when transfered
     */
    function SPAContractTransfer(
        address _SellerAddr,
        address _NewUserAddr,
        uint256 _Assetid,
        uint256 _NewAssetid
    )
        external
        returns (bool)
    {
        require(usermgt.IsBlackListed(_SellerAddr) == false, "Seller is BlackListed");
        require(usermgt.IsBlackListed(_NewUserAddr) == false, "Receiver is BlackListed");
        require(usermgt.IsUserListed(_NewUserAddr) == true, "Receiver is not Registered");
        require(msg.sender == _SellerAddr, "Only Seller can Transfer SPA");
        require(_NewUserAddr != address(0x0), "Receiver can't be empty");
        require(
            _SellerAddr != _NewUserAddr,
            "VesselTrust: Cannot Transfer to Self"
        );

        //Get the Old Contract to be transfered form
        SPAContract spaToTransfer = SPAUtils(_SellerAddr, _Assetid);

        // Get the New Contract to be Transfer to
        SPAContract NewSPAContract = SPAUtils(_NewUserAddr, _NewAssetid);

        //Get the Asset Details to be transfered
        (
            ,
            bytes32 _CommodityCode,
            bytes32 _Origin,
            bytes32 _LoadingTerminal,
            bytes32 _DeliveryDay
        ) = spaToTransfer.GetSPAContractData();

        //Save the Asset Details to the new contract
        bool transfering =
            NewSPAContract.SaveSPAContractData(
                _NewAssetid,
                _CommodityCode,
                _Origin,
                _LoadingTerminal,
                _DeliveryDay
            );

        if (transfering)
            SPAContractTransferCont1(
                _SellerAddr,
                _NewUserAddr,
                _Assetid,
                _NewAssetid
            );

        //Delete the Old SPA and plus the Sellers Deal by 1
        SPAContractTransferCont2(_SellerAddr, _Assetid, address(spaToTransfer));

        // Emit a transfer event
        emit SPATransfered(_NewUserAddr, _NewAssetid);

        return transfering;
    }

    /**
     * to transfer Assets from owner to a user continued
     * @param _SellerAddr Owner of the tokenized SPA
     * @param _NewUserAddr Receiver of the tokenized SPA
     * @param _Assetid The asset to transfer
     * @param _NewAssetid The New Asset ID when transfered
     */
    function SPAContractTransferCont1(
        address _SellerAddr,
        address _NewUserAddr,
        uint256 _Assetid,
        uint256 _NewAssetid
    ) internal returns (bool) {
        //Get the Asset Details to be transfered
        SPAContract spaToTransfer = SPAUtils(_SellerAddr, _Assetid);
        (
            bytes32 _Standard,
            bytes32 _Packaging,
            bytes32 _Quality,
            bytes32 _Quantity,
            bytes32 _BarrelPrice,
            bytes32 _ContractLength,
            bytes32 _Vessel,
            bytes32 _IMONumber,
            bytes32 _Procedure
        ) = spaToTransfer.GetSPAContractDetails();

        // Transfer to the new Owner
        SPAContract NewSPAContract = SPAUtils(_NewUserAddr, _NewAssetid);

        bool transfered =
            NewSPAContract.SaveSPAContractDetails(
                _Standard,
                _Packaging,
                _Quality,
                _Quantity,
                _BarrelPrice,
                _ContractLength,
                _Vessel,
                _IMONumber,
                _Procedure
            );

        // Emit a transfer event
        // emit SPATransfered(_NewUserAddr, _NewAssetid);

        return transfered;
    }

    /**
     * to transfer Assets from owner to a user continued
     * @param _SellerAddr Owner of the tokenized SPA
     * @param _Assetid The asset to transfer
     */
    function SPAContractTransferCont2(
        address _SellerAddr,
        uint256 _Assetid,
        address _spaToTransfer
    ) internal returns (bool) {
        // Delete the old Commodity and its details
        delete (commodity[_SellerAddr].assets[_Assetid]);

        spaDeal[_SellerAddr].SPADCompletedDeals.push(address(_spaToTransfer));

        return true;
    }

    /**
     * @dev Destroys Asset by setting the owner to 0.
     * Function must be called by the commodity Onwer.
     *
     * Emits a {BurntCommodity} event.
     */
    function BurnAsset(address _OwnerAddr, uint256 _Assetid)
        external
        returns (bool)
    {
        require(usermgt.IsBlackListed(_OwnerAddr) == false, "Owner is BlackListed");
        // Check if the owner of the commodity is making this call
        // require(commodity[_OwnerAddr].assets[_Assetid], 'VesselTrust: Owner has no such commodity');

        // tranfer the asset to a zero address
        delete (commodity[_OwnerAddr].assets[_Assetid]);

        emit BurntAsset(_OwnerAddr, _Assetid);

        return true;
    }

    
}

pragma solidity 0.5.0;

import "./Agreement.sol";
import "./SPAContract.sol";
import "./UserManagement.sol";

contract GetContractFactory {

    mapping(address => agreements) internal agreed;
    mapping(address => commodities) internal commodity;
    mapping(address => completedDeals) internal spaDeal;

        //Structs for Logic Contract
    struct commodities {
        SPAContract[] assets;
    }

    struct agreements {
        Agreement[] assets;
    }

    struct completedDeals {
        address[] SPADCompletedDeals;
    }

    //    ***********    Getters   ***********

    /**
     * return list of Aggreements addresses of VesselTrust
     *  @param _VTaddr Address to get all its Agreements
     */
    function AgreementList(address _VTaddr)
        external
        view
        returns (Agreement[] memory)
    {
        Agreement[] memory list = agreed[_VTaddr].assets;

        return list;
    }

    /**
     * to view Aggreement Data
     *  @param _VTaddr Address tof the Agreement
     *  @param _Assetid The ID of the Asset
     */
    function AgreementGet(address _VTaddr, uint256 _Assetid)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        Agreement aggreement = agreed[_VTaddr].assets[uint256(_Assetid)];

        return aggreement.GetAgreement();
    }

    /**
     * to view Aggreement Seller
     * @param _VTaddr Owner of the Agreement
     * @param _Assetid the asset
     */
    function AgreementSeller(address _VTaddr, uint256 _Assetid)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        Agreement agreementInfo = agreed[_VTaddr].assets[uint256(_Assetid)];

        return agreementInfo.GetAgreementSeller();
    }

    /**
     * to view Aggreement Buyer
     * @param _VTaddr Owner of the Agreement
     * @param _Assetid the asset
     */
    function AgreementBuyer(address _VTaddr, uint256 _Assetid)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        Agreement agreementInfo = agreed[_VTaddr].assets[uint256(_Assetid)];

        return agreementInfo.GetAgreementBuyer();
    }

    /**
     * to view Aggreement AccountOfficerDetails
     * @param _VTaddr Owner of the Agreement
     * @param _Assetid the asset
     */
    function AgreementACO(address _VTaddr, uint256 _Assetid)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        Agreement agreementInfo = agreed[_VTaddr].assets[uint256(_Assetid)];

        return agreementInfo.GetAgreementACO();
    }

    /**
     * to view Aggreement Details
     * @param _VTaddr Owner of the Agreement
     * @param _Assetid the asset
     */
    function AgreementDetail(address _VTaddr, uint256 _Assetid)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        Agreement agDetails = agreed[_VTaddr].assets[uint256(_Assetid)];

        return agDetails.GetAgreementDetails();
    }

    /**
     * return list of Asset SPAContract addresses of a User
     *  @param _Useraddr Address of the User to get all its assets.
     */
    function SellerSPAList(address _Useraddr)
        external
        view
        returns (SPAContract[] memory)
    {
        SPAContract[] memory list = commodity[_Useraddr].assets;

        return list;
    }

    /**
     * to view Seller's details of an SPA
     * @param _SellerAddr Owner of a tokenized SPA
     * @param _Assetid the Asset ID
     */
    function GetSPAContract(address _SellerAddr, uint256 _Assetid)
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        SPAContract spaInfo = commodity[_SellerAddr].assets[_Assetid];

        return spaInfo.GetSPAContract();
    }

    /**
     * to view Buyer's details of an SPA
     * @param _SellerAddr Owner of a tokenized SPA
     * @param _Assetid the Asset ID
     */
    function GetSPAContractData(address _SellerAddr, uint256 _Assetid)
        external
        view
        returns (
            uint256,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        SPAContract spaInfo = commodity[_SellerAddr].assets[_Assetid];

        return spaInfo.GetSPAContractData();
    }

    /**
     * to view Buyer's details of an SPA
     * @param _SellerAddr Owner of a tokenized SPA
     * @param _Assetid the Asset ID
     */
    function GetSPAContractDoc(address _SellerAddr, uint256 _Assetid)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32
        )
    {
        SPAContract spaInfo = commodity[_SellerAddr].assets[_Assetid];

        return spaInfo.GetSPAContractDoc();
    }

    /**
     * to view SPA METAData of an Asset
     * @param _SellerAddr Owner of the tokenized SPA
     * @param _Assetid the asset
     */
    function GetSPAContractDetails(address _SellerAddr, uint256 _Assetid)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        SPAContract spaInfo = commodity[_SellerAddr].assets[uint256(_Assetid)];

        return spaInfo.GetSPAContractDetails();
    }

}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //  constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: Division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: Modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./Libs/Context.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address _superAdmin) public initializer {
        _owner = _superAdmin;
        emit OwnershipTransferred(address(0x0), _owner);
    }

    // constructor() internal {
    //     _owner = msg.sender;
    //     emit OwnershipTransferred(address(0x0), _owner);
    // }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0x0));
        _owner = address(0x0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0x0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

// import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ExternalStorage.sol";

/**
 * @dev Registry Contract module.
 *
 * This module is used to create instance of the Receipt registration contract.
 */
contract SPAContract is ExternalStorage {
    mapping(address => address[]) internal agreementCollcetion;

    constructor(
        address _VTAddr,
        address _SellerAddr,
        address _BuyerAddr,
        address _agreementAddr
    ) public {
        vtDetails.VTAddr = _VTAddr;
        sellerDetails.SellerAddr = _SellerAddr;
        buyerDetails.BuyerAddr = _BuyerAddr;

        agreementCollcetion[_SellerAddr].push(_agreementAddr);
    }

    //     *************   SETTERS   ***************

    function SaveSPAContractData(
        uint256 _AssetID,
        bytes32 _CommodityCode,
        bytes32 _Origin,
        bytes32 _LoadingTerminal,
        bytes32 _DeliveryDay
    ) public returns (bool) {
        spacontractData.AssetID = _AssetID;
        spacontractData.CommodityCode = _CommodityCode;
        spacontractData.Origin = _Origin;
        spacontractData.LoadingTerminal = _LoadingTerminal;
        spacontractData.DeliveryDay = _DeliveryDay;

        return true;
    }

    function SaveSPAContractDoc(
        bytes32 _Doc1,
        bytes32 _Doc2,
        bytes32 _Doc3
    ) public returns (bool) {
        spacontractData.Doc1 = _Doc1;
        spacontractData.Doc2 = _Doc2;
        spacontractData.Doc3 = _Doc3;

        return true;
    }

    function SaveSPAContractDetails(
        bytes32 _Standard,
        bytes32 _Packaging,
        bytes32 _Quality,
        bytes32 _Quantity,
        bytes32 _BarrelPrice,
        bytes32 _ContractLength,
        bytes32 _Vessel,
        bytes32 _IMONumber,
        bytes32 _Procedure
    ) public returns (bool) {
        spacontractData.Standard = _Standard;
        spacontractDetails.Packaging = _Packaging;
        spacontractDetails.Quality = _Quality;
        spacontractDetails.Quantity = _Quantity;
        spacontractDetails.BarrelPrice = _BarrelPrice;
        spacontractDetails.ContractLength = _ContractLength;
        spacontractDetails.Vessel = _Vessel;
        spacontractDetails.IMONumber = _IMONumber;
        spacontractDetails.Procedure = _Procedure;

        return true;
    }

    //      ************  GETTERS   **************

    function GetSPAContract()
        public
        view
        returns (
            address,
            address,
            address
        )
    {
        return (
            vtDetails.VTAddr,
            sellerDetails.SellerAddr,
            buyerDetails.BuyerAddr
        );
    }

    function GetSPAContractData()
        public
        view
        returns (
            uint256,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            spacontractData.AssetID,
            spacontractData.CommodityCode,
            spacontractData.Origin,
            spacontractData.LoadingTerminal,
            spacontractData.DeliveryDay
        );
    }

    function GetSPAContractDoc()
        public
        view
        returns (
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            spacontractData.Doc1,
            spacontractData.Doc2,
            spacontractData.Doc3
        );
    }

    function GetSPAContractDetails()
        public
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (
            spacontractData.Standard,
            spacontractDetails.Packaging,
            spacontractDetails.Quality,
            spacontractDetails.Quantity,
            spacontractDetails.BarrelPrice,
            spacontractDetails.ContractLength,
            spacontractDetails.Vessel,
            spacontractDetails.IMONumber,
            spacontractDetails.Procedure
        );
    }
}

pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./ExternalStorage.sol";

/**
 * @dev Contract module for creates user management.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses of users, admin, whitelisting and blacklisting of users.
 */
contract UserManagement is Ownable, ExternalStorage {
    //     ***********     Modifiers    ************

    modifier adminExists(address _admin) {
        require(isAdmin[_admin], "Not an Admin");
        _;
    }

    modifier adminDoesNotExist(address admin) {
        require(!isAdmin[admin], "Admin already exists");
        _;
    }

    modifier authorizerDoesNotExist(address _authorizer) {
        require(!isAuthorizer[_authorizer], "Authorizer already exists");
        _;
    }

    modifier authorizerExists(address authorizer) {
        require(isAuthorizer[authorizer], "Address not Authorizer");
        _;
    }

    modifier checkUserList(address _user) {
        require(isUserListed[_user], "Not Registered User");
        _;
    }

    modifier checkBlackList(address _addr) {
        require(!isBlackListed[_addr], "User is BlackListed");
        _;
    }

    function initialize(address _superAdmin) public initializer {
        Ownable.initialize(_superAdmin);

        isUserListed[_superAdmin] = true;
        userList.push(_superAdmin);

        AddAdmin(_superAdmin, "SuperAdmin");

        isAuthorizer[_superAdmin] = true;
        authorizers.push(_superAdmin);
    }

    // constructor() public {
    //     isUserListed[_msgSender()] = true;
    //     userList.push(_msgSender());

    //     AddAdmin(_msgSender(), "SuperAdmin");

    //     isAuthorizer[_msgSender()] = true;
    //     authorizers.push(_msgSender());
    // }

    //        *************   Setters   *************

    function AddSuperAdmin(address _superAdminAddr, string memory _registrar)
        public
        onlyOwner
        returns (bool)
    {
        superAdmin[_registrar] = _superAdminAddr;
    }

    //Check if user is admin
    function IsAdmin(address _addr) public view returns (bool) {
        return isAdmin[_addr];
    }

    //Add platform Admin
    function AddAdmin(address _Admin, bytes32 _AdminName)
        public
        onlyOwner
        checkUserList(_Admin)
        adminDoesNotExist(_Admin)
        checkBlackList(_Admin)
        returns (bool)
    {
        if (!isUserListed[_Admin]) SetUserList(_Admin);

        Admins[_Admin] = AdminDetails(_Admin, _AdminName, _msgSender());
        admins.push(_msgSender());
        isAdmin[_Admin] = true;

        emit AdminAdded(_Admin);

        return true;
    }

    //Remove platform Admin
    function RemoveAdmin(address _addr)
        public
        onlyOwner
        adminExists(_addr)
        returns (bool)
    {
        isAdmin[_addr] = false;
        for (uint256 i = 0; i < admins.length - 1; i++)
            if (admins[i] == _addr) {
                admins[i] = admins[admins.length - 1];
                break;
            }

        admins.pop();
        delete Admins[_addr];

        emit AdminRemoved(_addr);

        return true;
    }

    function AddAuthorizer(address _authorizer)
        public
        checkUserList(_authorizer)
        adminExists(_msgSender())
        authorizerDoesNotExist(_authorizer)
        checkBlackList(_authorizer)
        returns (bool)
    {
        isAuthorizer[_authorizer] = true;
        authorizers.push(_authorizer);

        emit AuthorizerAdded(_authorizer);

        return true;
    }

    //Remove an Authorizer
    function RemoveAuthorizer(address _authorizer)
        public
        adminExists(_msgSender())
        authorizerExists(_authorizer)
        returns (bool)
    {
        isAuthorizer[_authorizer] = false;
        for (uint256 i = 0; i < authorizers.length - 1; i++)
            if (authorizers[i] == _authorizer) {
                authorizers[i] = authorizers[authorizers.length - 1];
                break;
            }
        authorizers.pop();

        emit AuthorizerRemoved(_authorizer);

        return true;
    }

    //Check if user is Blacklisted
    function IsBlackListed(address _addr) public view returns (bool) {
        return isBlackListed[_addr];
    }

    // Add adress to the BlackList
    function AddBlackList(address _evilUser)
        public
        adminExists(_msgSender())
        checkUserList(_evilUser)
        checkBlackList(_evilUser)
    {
        if (isAdmin[_evilUser]) {
            RemoveAdmin(_evilUser);
        }
        if (isAuthorizer[_evilUser]) {
            RemoveAuthorizer(_evilUser);
        }

        blackList.push(_evilUser);
        isBlackListed[_evilUser] = true;

        emit SetBlackListEvent(_evilUser);
    }

    // Remove Address from the BlackList
    function RemoveBlackList(address _clearedUser)
        public
        adminExists(_msgSender())
        returns (bool)
    {
        require(isBlackListed[_clearedUser], "Address not BlackListed");

        for (uint256 i = 0; i < userList.length - 1; i++)
            if (blackList[i] == _clearedUser) {
                blackList[i] = blackList[blackList.length - 1];
                break;
            }
        blackList.pop();
        isBlackListed[_clearedUser] = false;

        emit RemoveUserBlackList(_clearedUser);

        return true;
    }

    //Check if user is Registered
    function IsUserListed(address _addr) public view returns (bool) {
        return isUserListed[_addr];
    }
    
    //Add Users on the platform
    function SetUserList(address _addr)
        public
        adminExists(_msgSender())
        checkBlackList(_addr)
        returns (bool)
    {
        require(!isUserListed[_addr], "Address already Registered");

        isUserListed[_addr] = true;
        userList.push(_addr);

        emit SetUserListEvent(_addr);

        return true;
    }

    //Remove Users from the platform
    function RemoveUserList(address _addr)
        public
        adminExists(_msgSender())
        checkUserList(_addr)
        returns (bool)
    {
        isUserListed[_addr] = false;
        for (uint256 i = 0; i < userList.length - 1; i++)
            if (userList[i] == _addr) {
                userList[i] = userList[userList.length - 1];
                break;
            }
        userList.pop();

        emit RemovedUserList(_addr);

        return true;
    }

    //        *************   Getter   *************

    //Get list of Whitelisted Users
    function getUserList()
        public
        view
        adminExists(_msgSender())
        returns (address[] memory)
    {
        return userList;
    }

    //Get list of BlackListed Users
    function getBlackList()
        public
        view
        adminExists(_msgSender())
        returns (address[] memory)
    {
        return blackList;
    }
}