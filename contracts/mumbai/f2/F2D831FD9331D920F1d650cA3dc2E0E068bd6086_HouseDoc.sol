// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract HouseDoc {
    address private _owner;
    // total number of contract
    uint256 public hdCounter;

    // houseNFT contract address
    address public houseNFTAddress;

    // Operator address
    address public operatorAddress;

    // define contract struct
    struct DocContract {
        uint256 contractId;
        string companyName;
        uint256 contractType;
        string contractURI;
        uint256 dateFrom;
        uint256 dateTo;
        uint256 agreedPrice;
        string currency;
        address creator;
        address owner;
        address contractSigner;
        bool creatorApproval;
        uint256 creatorSignDate;
        bool signerApproval;
        uint256 signerSignDate;
        string status;
    }

    // define notification 6
    struct Notify {
        address nSender;
        address nReceiver;
        uint256 hdID;
        uint256 notifySentTime;
        string notifyContent;
        bool status;
    }

    // map house"s token id to house
    mapping(uint256 => DocContract) allDocContracts;
    // notifications
    mapping(address => Notify[]) allNotifies;

    event DocContractCreated(
        uint256 indexed hdID,
        address indexed owner,
        address indexed creator,
        string companyName,
        uint256 contractType,
        address contractSigner,
        string contractURI,
        uint256 dateFrom,
        uint256 dateTo,
        uint256 agreedPrice,
        string currency,
        string status
    );
    event ContractSignerAdded(address indexed creator, uint256 indexed hdID, address contractSigner);
    event ContractSigned(address indexed signer, uint256 hdID, string status);
    event NotifySent(address indexed sender, address indexed receiver, uint256 hdID, uint256 sentTime, string content);

    constructor(address addr) {
        houseNFTAddress = addr;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'ERC20: Only owner can run this event');
        _;
    }

    function setOperatorAddress(address _address) public onlyOwner {
        operatorAddress = _address;
    }

    // write Contract
    function hdCreation(
        string memory _companyName,
        uint256 _contractType,
        address _contractSigner,
        string memory _contractURI,
        uint256 _dateFrom,
        uint256 _dateTo,
        uint256 _agreedPrice,
        string memory _currency,
        address _user
    ) public {
        address user = msg.sender == operatorAddress ? _user : msg.sender;
        require(_dateFrom < _dateTo, "Start date must be before end date");
        require(_agreedPrice > 0, "Agreed price must be greater than 0");
        require(_user != _contractSigner, "Owner can't be signer");

        hdCounter++;

        allDocContracts[hdCounter].contractId = hdCounter;
        allDocContracts[hdCounter].owner = user;
        allDocContracts[hdCounter].creator = user;
        allDocContracts[hdCounter].contractURI = _contractURI;
        allDocContracts[hdCounter].companyName = _companyName;
        allDocContracts[hdCounter].contractType = _contractType;
        allDocContracts[hdCounter].dateFrom = _dateFrom;
        allDocContracts[hdCounter].dateTo = _dateTo;
        allDocContracts[hdCounter].agreedPrice = _agreedPrice;
        allDocContracts[hdCounter].currency = _currency;
        allDocContracts[hdCounter].status = "pending";
        allDocContracts[hdCounter].contractSigner = _contractSigner;
        allDocContracts[hdCounter].creatorApproval = false;
        allDocContracts[hdCounter].signerApproval = false;

        emit DocContractCreated(
            hdCounter,
            user,
            user,
            _companyName,
            _contractType,
            _contractSigner,
            _contractURI,
            _dateFrom,
            _dateTo,
            _agreedPrice,
            _currency,
            "pendig"
        );
    }

    // Add Contract Signer
    function addContractSigner(uint256 _ccID, address _contractSigner) public {
        DocContract storage singleContract = allDocContracts[_ccID];
        require(singleContract.owner == msg.sender || operatorAddress == msg.sender, "Only contract owner can add contract signer");
        require(singleContract.owner != _contractSigner, "Owner can't be signer");
        singleContract.contractSigner = _contractSigner;

        emit ContractSignerAdded(msg.sender, _ccID, _contractSigner);
    }

    // sign contract
    function signContract(uint256 hdID, address _newSigner) public {
        DocContract storage singleContract = allDocContracts[hdID];
        require(
            msg.sender == singleContract.owner || msg.sender == singleContract.contractSigner || msg.sender == operatorAddress,
            "You don't have permission to this contract"
        );
        if (_newSigner == singleContract.owner) {
            singleContract.creatorApproval = true;
            if (singleContract.signerApproval == true) {
                singleContract.status = "signed";
                singleContract.creatorSignDate = block.timestamp;
            }
            for (uint256 i = 0; i < allNotifies[singleContract.owner].length; i++) {
                if (allNotifies[singleContract.owner][i].hdID == hdID) {
                    allNotifies[singleContract.owner][i].status = true;
                }
            }
            emit ContractSigned(_newSigner, hdID, "signed");
        } else if (_newSigner == singleContract.contractSigner) {
            singleContract.signerApproval = true;
            if (singleContract.creatorApproval == true) {
                singleContract.status = "signed";
                singleContract.signerSignDate = block.timestamp;
            }
            for (uint256 i = 0; i < allNotifies[singleContract.contractSigner].length; i++) {
                if (allNotifies[singleContract.contractSigner][i].hdID == hdID) {
                    allNotifies[singleContract.contractSigner][i].status = true;
                }
            }
            emit ContractSigned(_newSigner, hdID, "signed");
        }
    }

    // send sign notification
    function sendNotify(address _notifyReceiver, string memory _notifyContent, uint256 hdID, address _notifier) external {
        DocContract storage hdContract = allDocContracts[hdID];
        require(hdContract.contractSigner != address(0), "Please add contract signer.");
        Notify[] storage notifies = allNotifies[hdContract.contractSigner];
        if (notifies.length >= 5) {
            require(
                notifies[notifies.length - 1].notifySentTime + 24 * 3600 <= block.timestamp,
                "You can send notify once per day."
            );
        }
        Notify memory newNotify = Notify({
            nSender: _notifier,
            nReceiver: _notifyReceiver,
            hdID: hdID,
            notifySentTime: block.timestamp,
            notifyContent: _notifyContent,
            status: false
        });
        allNotifies[_notifyReceiver].push(newNotify);

        emit NotifySent(_notifier, _notifyReceiver, hdID, block.timestamp, _notifyContent);
    }

    function getAllDocContracts() external view returns (DocContract[] memory) {
        DocContract[] memory contracts = new DocContract[](hdCounter);
        for (uint256 i = 0; i < hdCounter; i++) {
            contracts[i] = allDocContracts[i + 1];
        }
        return contracts;
    }

    // get my all notifies
    function getAllNotifies(address _address) external view returns (Notify[] memory) {
        return allNotifies[_address];
    }

    /**
     * @dev returns contract with id as `contractId`
     *
     * NOTE only houseNFT contract can call
     */
    function getContractById(uint256 contractId) external view returns (address _contractOwner) {
        require(msg.sender == houseNFTAddress, "only NFT");
        _contractOwner = allDocContracts[contractId].owner;
    }

    // declare this function for use in the following 3 functions
    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // cast address to string
    function addressToString(address account) internal pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /**
     * @dev modifies ownership of `contractId` from `from` to `to`
     */
    function transferContractOwnership(uint256 contractId, address from, address to) external {
        require(msg.sender == houseNFTAddress, "Only house contract");

        DocContract storage singleContract = allDocContracts[contractId];
        require(singleContract.owner == from, "Only owner can call this function");
        singleContract.owner = to;
    }
}