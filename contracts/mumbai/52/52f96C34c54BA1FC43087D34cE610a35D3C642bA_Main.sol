//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Session.sol";
import "./SessionDetail.sol";

contract Main {
    struct IParticipant {
        address account;
        string fullName;
        string email;
        uint256 numberOfJoinedSession;
        uint256 deviation;
    }

    event RegisterSuccess(address account, string fullName, string email);
    event UpdateUser(
        address account,
        string fullName_old,
        string email_old,
        string fullName_new,
        string email_new
    );
    event CreateSession(address sessionAddress);

    address public admin;
    address[] public addressParticipant;
    mapping(address => IParticipant) public participants;

    address[] public addressSessions;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Main: not is admin");
        _;
    }
    modifier onlySession() {
        bool check = false;
        for (uint i = 0; i < addressSessions.length; i++) {
            if (addressSessions[i] == msg.sender) {
                check = true;
            }
        }
        require(check == true, "Main: Only session contract");
        _;
    }

    function register(string memory _fullName, string memory _email) public {
        require(
            participants[msg.sender].account == address(0x0),
            "Main: user registered"
        );

        IParticipant memory newIParticipant = IParticipant({
            account: msg.sender,
            fullName: _fullName,
            email: _email,
            numberOfJoinedSession: 0,
            deviation: 0
        });
        participants[msg.sender] = newIParticipant;
        addressParticipant.push(msg.sender);

        emit RegisterSuccess(msg.sender, _fullName, _email);
    }

    function createNewSession(
        string memory _productName,
        string memory _productDescription,
        string[] memory _productImage
    ) external onlyAdmin {
        Session newSession = new Session(
            _productName,
            _productDescription,
            _productImage,
            address(this),
            msg.sender
        );
        addressSessions.push(address(newSession));
        emit CreateSession(address(newSession));
    }

    function updateInfomationByUser(
        string memory _fullName,
        string memory _email
    ) public {
        require(
            participants[msg.sender].account == msg.sender,
            "Main: unregisted user or wrong account"
        );
        string memory _nameOld = participants[msg.sender].fullName;
        string memory _emailOld = participants[msg.sender].email;
        participants[msg.sender].fullName = _fullName;
        participants[msg.sender].email = _email;
        emit UpdateUser(msg.sender, _nameOld, _emailOld, _fullName, _email);
    }

    function updateInfomationByAdmin(
        address _account,
        string memory _fullName,
        string memory _email,
        uint _numberOfJoinedSession,
        uint _deviation
    ) public onlySession {
        require(
            participants[_account].account == _account,
            "Main: unregisted user or wrong account"
        );
        participants[_account].fullName = _fullName;
        participants[_account].email = _email;
        participants[_account].numberOfJoinedSession = _numberOfJoinedSession;
        participants[_account].deviation = _deviation;
    }

    function getParticipantAccount(
        address _address
    ) external view returns (address) {
        return participants[_address].account;
    }

    function getDeviationParticipant(
        address _account
    ) external view returns (uint) {
        return participants[_account].deviation;
    }

    function getNumberOfJoinedSession(
        address _account
    ) external view returns (uint) {
        return participants[_account].numberOfJoinedSession;
    }

    function updateDeviationForParticipant(
        address _account,
        uint _deviation,
        uint _numberOfJoinedSession
    ) external onlySession {
        participants[_account].deviation = _deviation;
        participants[_account].numberOfJoinedSession = _numberOfJoinedSession;
    }

    function getInforParticipants()
        external
        view
        onlyAdmin
        returns (IParticipant[] memory)
    {
        IParticipant[] memory _paticipants = new IParticipant[](
            addressParticipant.length
        );

        for (uint i = 0; i < addressParticipant.length; i++) {
            IParticipant memory newPaticipant = participants[
                addressParticipant[i]
            ];
            _paticipants[i] = newPaticipant;
        }
        return _paticipants;
    }

    function getAddressSession() public view returns (address[] memory) {
        return addressSessions;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Main.sol";
import "./SessionDetail.sol";

contract Session {
    string productName;
    string productDescription;
    string[] productImages;
    address[] participantJoinSession;
    address public admin;
    uint public proposePrice;
    uint public finalPrice;
    uint multi = 10 ** 18;
    mapping(address => uint) priceVoteByParticipant;
    Main MainContract;

    //enum State { CREATE,VOTTING, CLOSING,CLOSED }
    State state;

    event Vote(address account, uint numberVote);
    event CaclculatePropose(uint numberPropose);
    event StateChange(string State);

    constructor(
        string memory _productName,
        string memory _productDescription,
        string[] memory _productImages,
        address _mainContract,
        address _admin
    ) {
        productName = _productName;
        productDescription = _productDescription;
        productImages = _productImages;
        MainContract = Main(_mainContract);
        admin = _admin;
        state = State.CREATE;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Session: not is admin");
        _;
    }

    modifier onlyMain() {
        require(
            msg.sender == address(MainContract),
            "Session: not is Main Constract"
        );
        _;
    }

    modifier onlyRegitsted(address _address) {
        require(
            MainContract.getParticipantAccount(_address) != address(0x0),
            "Session: Not registered"
        );
        _;
    }

    modifier onlyState(State _state) {
        require(
            _state == state,
            "Session: the operation is not valid in the state "
        );
        _;
    }

    function checkJoinSession(address _account) private view returns (bool) {
        for (uint i = 0; i < participantJoinSession.length; i++) {
            if (participantJoinSession[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function alowVotingState() public onlyAdmin onlyState(State.CREATE) {
        state = State.VOTTING;
        emit StateChange("Votting");
    }

    function alowClosingState() public onlyAdmin onlyState(State.VOTTING) {
        state = State.CLOSING;
        emit StateChange("Closing");
    }

    function alowClosedSate() public onlyAdmin onlyState(State.VOTTING) {
        state = State.CLOSED;
        emit StateChange("Closed");
    }

    function getState() public view returns (State) {
        return state;
    }

    function vote(
        uint _price
    ) public onlyRegitsted(msg.sender) onlyState(State.VOTTING) {
        if (checkJoinSession(msg.sender)) {
            priceVoteByParticipant[msg.sender] = _price;
        } else {
            participantJoinSession.push(msg.sender);
            priceVoteByParticipant[msg.sender] = _price;
        }
        emit Vote(msg.sender, _price);
    }

    function caclculatePropose()
        public
        onlyAdmin
        onlyState(State.CLOSING)
        returns (uint)
    {
        uint numerator = 0;
        uint sumDeviation = 0;
        for (uint i = 0; i < participantJoinSession.length; i += 1) {
            address addPaticipant = participantJoinSession[i];
            uint deviPaticipant = MainContract.getDeviationParticipant(
                addPaticipant
            );
            numerator +=
                priceVoteByParticipant[addPaticipant] *
                (100 * multi - deviPaticipant);

            sumDeviation += deviPaticipant;
        }

        proposePrice =
            numerator /
            (100 * multi * participantJoinSession.length);
        emit CaclculatePropose(proposePrice);
        return proposePrice;
    }

    function updatePropose(
        uint _newPropose
    ) public onlyAdmin onlyState(State.CLOSING) {
        finalPrice = _newPropose;
    }

    function calculateDeviation() public onlyAdmin onlyState(State.CLOSING) {
        for (uint i = 0; i < participantJoinSession.length; i += 1) {
            address addPaticipant = participantJoinSession[i];
            uint deviPaticipant = MainContract.getDeviationParticipant(
                addPaticipant
            );
            uint numberOfJoinedSession = MainContract.getNumberOfJoinedSession(
                addPaticipant
            );
            uint deviant;

            if (finalPrice >= priceVoteByParticipant[addPaticipant]) {
                deviant = finalPrice - priceVoteByParticipant[addPaticipant];
            } else {
                deviant = priceVoteByParticipant[addPaticipant] - finalPrice;
            }

            uint _dnew = (deviant * 100 * multi) / finalPrice;

            uint deviationForParticipan = (deviPaticipant *
                numberOfJoinedSession +
                _dnew) / (numberOfJoinedSession + 1);

            MainContract.updateDeviationForParticipant(
                addPaticipant,
                deviationForParticipan,
                numberOfJoinedSession + 1
            );
            state = State.CLOSED;
        }
    }

    function getSessionDetailForuser()
        external
        view
        returns (SessionDetail memory)
    {
        SessionDetail memory _session = SessionDetail({
            sessionAddress: address(this),
            productName: productName,
            productDescription: productDescription,
            productImages: productImages,
            proposedPrice: finalPrice,
            finalPrice: finalPrice,
            state: state
        });
        return _session;
    }

    function getSessionDetailforAdmin()
        external
        view
        onlyAdmin
        returns (SessionDetail memory)
    {
        SessionDetail memory _session = SessionDetail({
            sessionAddress: address(this),
            productName: productName,
            productDescription: productDescription,
            productImages: productImages,
            proposedPrice: finalPrice,
            finalPrice: finalPrice,
            state: state
        });
        return _session;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

enum State {
    CREATE,
    VOTTING,
    CLOSING,
    CLOSED
}

struct SessionDetail {
    address sessionAddress;
    string productName;
    string productDescription;
    string[] productImages;
    uint256 proposedPrice;
    uint256 finalPrice;
    State state;
}