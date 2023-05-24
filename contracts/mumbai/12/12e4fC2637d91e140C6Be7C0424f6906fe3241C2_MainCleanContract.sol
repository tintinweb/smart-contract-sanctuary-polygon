// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract MainCleanContract {
    address private _owner;

    // total number of contract
    uint256 public ccCounter;

    // houseNFT contract address
    address public houseNFTAddress;

    // Operator address
    address public operatorAddress;

    // define contract struct
    struct CleanContract {
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
        uint256 ccID;
        uint256 notifySentTime;
        string notifyContent;
        bool status;
    }

    // map house"s token id to house
    mapping(uint256 => CleanContract) allCleanContracts;
    // notifications
    mapping(address => Notify[]) allNotifies;

    event CleanContractCreated(
        uint256 indexed ccID,
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
    event ContractSignerAdded(address indexed creator, uint256 indexed ccID, address contractSigner);
    event ContractSigned(address indexed signer, uint256 ccID, string status);
    event NotifySent(address indexed sender, address indexed receiver, uint256 ccID, uint256 sentTime, string content);

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
    function ccCreation(
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
        require(_dateFrom < _dateTo, 'Start date must be before end date');
        require(_agreedPrice > 0, 'Agreed price must be greater than 0');
        require(_user != _contractSigner && msg.sender != _contractSigner, "Owner can't be signer");

        ccCounter++;

        allCleanContracts[ccCounter].contractId = ccCounter;
        allCleanContracts[ccCounter].owner = _user;
        allCleanContracts[ccCounter].creator = _user;
        allCleanContracts[ccCounter].contractURI = _contractURI;
        allCleanContracts[ccCounter].companyName = _companyName;
        allCleanContracts[ccCounter].contractType = _contractType;
        allCleanContracts[ccCounter].dateFrom = _dateFrom;
        allCleanContracts[ccCounter].dateTo = _dateTo;
        allCleanContracts[ccCounter].agreedPrice = _agreedPrice;
        allCleanContracts[ccCounter].currency = _currency;
        allCleanContracts[ccCounter].status = 'pending';
        allCleanContracts[ccCounter].contractSigner = _contractSigner;
        allCleanContracts[ccCounter].creatorApproval = false;
        allCleanContracts[ccCounter].signerApproval = false;

        emit CleanContractCreated(
            ccCounter,
            _user,
            _user,
            _companyName,
            _contractType,
            _contractSigner,
            _contractURI,
            _dateFrom,
            _dateTo,
            _agreedPrice,
            _currency,
            'pendig'
        );
    }

    // Add Contract Signer
    function addContractSigner(uint256 _ccID, address _contractSigner) public {
        CleanContract storage singleContract = allCleanContracts[_ccID];
        require(singleContract.owner == msg.sender || operatorAddress == msg.sender, 'Only contract owner can add contract signer');
        require(singleContract.owner != _contractSigner, "Owner can't be signer");
        singleContract.contractSigner = _contractSigner;

        emit ContractSignerAdded(singleContract.owner, _ccID, _contractSigner);
    }

    // sign contract
    function signContract(uint256 ccID, address _newSigner) public {
        CleanContract storage singleContract = allCleanContracts[ccID];
        require(
            msg.sender == singleContract.creator || msg.sender == singleContract.contractSigner || msg.sender == operatorAddress,
            "You don't have permission to this contract"
        );
        uint256 flag = 0;
        if (_newSigner == singleContract.creator) {
            singleContract.creatorApproval = true;
            if (singleContract.signerApproval == true) {
                singleContract.status = 'signed';
                singleContract.creatorSignDate = block.timestamp;
                flag = 1;

                emit ContractSigned(_newSigner, ccID, 'signed');
            }
        } else if (_newSigner == singleContract.contractSigner) {
            singleContract.signerApproval = true;
            if (singleContract.creatorApproval == true) {
                singleContract.status = 'signed';
                singleContract.signerSignDate = block.timestamp;
                flag = 2;

                emit ContractSigned(_newSigner, ccID, 'signed');
            }
        }
        if (flag == 1) {
            for (uint256 i = 0; i < allNotifies[singleContract.creator].length; i++) {
                if (allNotifies[singleContract.creator][i].ccID == ccID) {
                    allNotifies[singleContract.creator][i].status = true;
                }
            }
        } else if (flag == 2) {
            for (uint256 i = 0; i < allNotifies[singleContract.contractSigner].length; i++) {
                if (allNotifies[singleContract.contractSigner][i].ccID == ccID) {
                    allNotifies[singleContract.contractSigner][i].status = true;
                }
            }
        } else {
            address _notifyReceiver;
            if (_newSigner == singleContract.creator) {
                _notifyReceiver = singleContract.contractSigner;
            } else {
                _notifyReceiver = singleContract.creator;
            }

            string memory stringAddress = addressToString(_newSigner);
            string memory notifyMsg = append('New signing request from ', stringAddress);

            Notify memory newNotify = Notify({
                nSender: _newSigner,
                nReceiver: _notifyReceiver,
                ccID: ccID,
                notifySentTime: 0,
                notifyContent: notifyMsg,
                status: false
            });
            allNotifies[_notifyReceiver].push(newNotify);
        }
    }

    // send sign notification
    function sendNotify(
        address _notifyReceiver,
        string memory _notifyContent,
        uint256 ccID,
        address _notifier
    ) external {
        CleanContract storage cContract = allCleanContracts[ccID];
        require(cContract.contractSigner != address(0), 'Please add contract signer.');
        Notify[] storage notifies = allNotifies[cContract.contractSigner];
        if (notifies.length >= 5) {
            require(
                notifies[notifies.length - 1].notifySentTime + 24 * 3600 <= block.timestamp,
                'You can send notify once per day.'
            );
        }
        Notify memory newNotify = Notify({
            nSender: _notifier,
            nReceiver: _notifyReceiver,
            ccID: ccID,
            notifySentTime: block.timestamp,
            notifyContent: _notifyContent,
            status: false
        });
        allNotifies[_notifyReceiver].push(newNotify);

        emit NotifySent(_notifier, _notifyReceiver, ccID, block.timestamp, _notifyContent);
    }

    function getAllCleanContracts() external view returns (CleanContract[] memory) {
        CleanContract[] memory contracts = new CleanContract[](ccCounter);
        for (uint256 i = 0; i < ccCounter; i++) {
            contracts[i] = allCleanContracts[i + 1];
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
        require(msg.sender == houseNFTAddress, 'only NFT');
        return allCleanContracts[contractId].owner;
    }

    // declare this function for use in the following 3 functions
    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
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
        require(msg.sender == houseNFTAddress, 'Only house contract');

        CleanContract storage singleContract = allCleanContracts[contractId];
        require(singleContract.owner == from, 'Only owner can call this function');
        singleContract.owner = to;
    }
}