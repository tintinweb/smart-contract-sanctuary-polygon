/**
 *Submitted for verification at polygonscan.com on 2022-11-01
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFTCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFTController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFM() external pure returns (address);

    function _getAFT() external view returns (address);

    function _getDaoYield() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getContributor() external pure returns (address);

    function _getNFM() external view returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFT
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFT {
    function balanceOf(address account) external view returns (uint256);

    function _returnTokenReference(address account)
        external
        view
        returns (uint256, uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFM
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFM {
    function balanceOf(address account) external view returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMContributor
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFMContributor {
    function _returnIsContributor(address NFMAddress)
        external
        view
        returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title AFTGeneralPulling.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract manages all elections, as well as all election topics that do not receive execution authorization. Within these
//                 elections, subject areas are led to execution levels, however, execution rights are only executed separately within special
//                 elections of the AFT community.
/// @dev    Elections can be made and evaluated at different levels.
//                - Level 1 Elections only for AFT members, these can also be created exclusively by AFT members.
//                - Level 2 Elections only for contributors, these can only be created by contributors.
//                - Level 3 Elections for NFM members only, these can be created by contributors and NFM members.
//                - Level 4 These elections are for all members. NFM Community, Contributor, and AFT members can vote in these
//                               elections. However, the elections can only be created by AFT members. The subject area concerns important
//                               events.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract AFTFULLPULLINGS {
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //PULL STRUCT
    /*
    Contains all Pulling Information
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    struct GeneralPulls {
        uint256 PullId;
        string PullTitle;
        string PullDescription;
        uint256 PullTyp;
        address Requester;
        uint256 Terminated;
        uint256 VotingThema;
        bool PullVoteapproved;
        uint256 Timestart;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //VARIABLES
    /*
    @ StaticGpullcounter = Pulling Counter
    @ allpulls = Array with all Pullings
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public StaticGpullcounter = 0;
    GeneralPulls[] public allpulls;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    IAFTController public _AFTController;
    INfmController public _NFMController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    @ gPulls (PullID => PullInformation)
    @ VotesAll (PullID => VoterAdress => Vote)
    @ HasVoted (PullID => VoterAdress => boolean Int)
    @ _NFMVotescounter (PullID => Bool => Counter of all Votes)
    @ _ConVotescounter (PullID => Bool => Counter of all Votes)
    @ AllAftcounts (PullID => Bool => Counter of all Votes)
    @ _AdressesVotescounter (PullID => Array of all Voting Adresses)
    @ AFTIdVotes (PullID => AFTTOKENID => Vote)
    @ AFThasVoted (PullID => AFTTOKENID => boolean Int)
    @ _AFTVotescounter (PullID => Array of AFT TokenIDs)
    @ _AFTAdressesVotescounter (PullID => Array of AFT Adresses)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(uint256 => GeneralPulls) public gPulls;
    mapping(uint256 => mapping(address => bool)) private VotesAll;
    mapping(uint256 => mapping(address => uint256)) private HasVoted;
    mapping(uint256 => mapping(bool => uint256)) private _NFMVotescounter;
    mapping(uint256 => mapping(bool => uint256)) private _ConVotescounter;
    mapping(uint256 => address[]) private _AdressesVotescounter;
    mapping(uint256 => mapping(bool => uint256)) private AllAftcounts;
    mapping(uint256 => mapping(uint256 => bool)) private AFTIdVotes;
    mapping(uint256 => mapping(uint256 => uint256)) private AFThasVoted;
    mapping(uint256 => uint256[]) private _AFTVotescounter;
    mapping(uint256 => address[]) private _AFTAdressesVotescounter;

    constructor(address AFTCon, address NFMCon) {
        _Owner = msg.sender;
        IAFTController _AFTCo = IAFTController(address(AFTCon));
        INfmController _NFMCo = INfmController(address(NFMCon));
        _AFTController = _AFTCo;
        _NFMController = _NFMCo;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnPullTheme(uint256 PullID) 
    Returns the Theme from a pull 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnPullTheme(uint256 PullID) public view returns (uint256) {
        return gPulls[PullID].VotingThema;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnAFTVotes(uint256 PullID)
    Returns all addresses and TokenID from a pull at AFT level
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnAFTVotes(uint256 PullID)
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256
        )
    {
        return (
            _AFTVotescounter[PullID],
            _AFTAdressesVotescounter[PullID],
            _AFTVotescounter[PullID].length
        );
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnAddressesOnVotes(uint256 PullID)
    Returns all addresses from a pull at NFM and Contributor level
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnAddressesOnVotes(uint256 PullID)
        public
        view
        returns (address[] memory, uint256)
    {
        return (
            _AdressesVotescounter[PullID],
            _AdressesVotescounter[PullID].length
        );
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnVotesCounterAll(uint256 PullID,bool Vote, uint256 Type)
    Returns all ballots from a pull 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnVotesCounterAll(
        uint256 PullID,
        bool Vote,
        uint256 Type
    ) public view returns (uint256) {
        if (Type == 1) {
            return AllAftcounts[PullID][Vote];
        } else if (Type == 2) {
            return _ConVotescounter[PullID][Vote];
        } else if (Type == 3) {
            return _NFMVotescounter[PullID][Vote];
        } else {
            return (_NFMVotescounter[PullID][Vote] +
                _ConVotescounter[PullID][Vote] +
                AllAftcounts[PullID][Vote]);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnAFTVoted(uint256 PullID, uint256 AFTID)
    Returns all ballots from a pull at AFT level 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnAFTVoted(uint256 PullID, uint256 AFTID)
        public
        view
        returns (uint256, bool)
    {
        return (AFThasVoted[PullID][AFTID], AFTIdVotes[PullID][AFTID]);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnVotesOnLevel(uint256 PullID, uint256 AFTID)
    Checks the Vote on an AFT Member
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnVotesOnAFTLevel(uint256 PullID, uint256 AFTID)
        public
        view
        returns (uint256, bool)
    {
        return (AFThasVoted[PullID][AFTID], AFTIdVotes[PullID][AFTID]);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ storePull(address Sender,string calldata PullTitle,string calldata PullDescription,uint256 PullTyp,uint256 Terminated,uint256 VotingThema,
        bool PullVoteapproved)
    Store Pulling Information
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function storePull(
        address Sender,
        string calldata PullTitle,
        string calldata PullDescription,
        uint256 PullTyp,
        uint256 Terminated,
        uint256 VotingThema,
        bool PullVoteapproved
    ) public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(
            _AFTController._checkWLSC(address(_AFTController), msg.sender) ==
                true,
            "oO"
        );
        gPulls[StaticGpullcounter] = GeneralPulls(
            StaticGpullcounter,
            PullTitle,
            PullDescription,
            PullTyp,
            Sender,
            Terminated,
            VotingThema,
            PullVoteapproved,
            block.timestamp
        );
        allpulls.push(gPulls[StaticGpullcounter]);
        StaticGpullcounter++;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnPullsOnLevel(uint256 Level)
    Return ongoing Pullings by Level
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnPullsOnLevel(uint256 Level)
        public
        view
        returns (GeneralPulls[] memory)
    {
        uint256 counting = 0;
        for (uint256 i = 0; i < allpulls.length; i++) {
            if (
                allpulls[i].PullTyp == Level &&
                (allpulls[i].Terminated > block.timestamp) &&
                (gPulls[i].PullVoteapproved == true)
            ) {
                counting++;
            }
        }
        GeneralPulls[] memory Ids = new GeneralPulls[](counting);
        uint256 nextcount = 0;
        for (uint256 i = 0; i < allpulls.length; i++) {
            if (
                allpulls[i].PullTyp == Level &&
                (allpulls[i].Terminated > block.timestamp) &&
                (gPulls[i].PullVoteapproved == true)
            ) {
                Ids[nextcount] = allpulls[i];
                nextcount++;
            }
        }
        return Ids;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnPullsOnLevelEnded(uint256 Level)
    Return ended Pullings by Level
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnPullsOnLevelEnded(uint256 Level)
        public
        view
        returns (GeneralPulls[] memory)
    {
        uint256 counting = 0;
        for (uint256 i = 0; i < allpulls.length; i++) {
            if (
                allpulls[i].PullTyp == Level &&
                (allpulls[i].Terminated < block.timestamp) &&
                (gPulls[i].PullVoteapproved == true)
            ) {
                counting++;
            }
        }
        GeneralPulls[] memory Ids = new GeneralPulls[](counting);
        uint256 nextcount = 0;
        for (uint256 i = 0; i < allpulls.length; i++) {
            if (
                allpulls[i].PullTyp == Level &&
                (allpulls[i].Terminated < block.timestamp) &&
                (gPulls[i].PullVoteapproved == true)
            ) {
                Ids[nextcount] = allpulls[i];
                nextcount++;
            }
        }
        return Ids;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ saveContVote(uint256 PullID, bool Vote)
    Save my decision as Contributor
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function saveContVote(uint256 PullID, bool Vote) public returns (bool) {
        require(HasVoted[PullID][msg.sender] != 1, "AV"); //Check if voted
        require(
            INFMContributor(address(_NFMController._getContributor()))
                ._returnIsContributor(msg.sender) == true,
            "NA"
        ); //Check if contributor
        require(
            INFM(address(_NFMController._getNFM())).balanceOf(msg.sender) >=
                100 * 10**18,
            "NB"
        ); //Check if 100NFM on balance

        HasVoted[PullID][msg.sender] = 1;
        VotesAll[PullID][msg.sender] = Vote;
        _ConVotescounter[PullID][Vote] += 1;
        _AdressesVotescounter[PullID].push(msg.sender);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ saveNFMVote(uint256 PullID, bool Vote)
    Save my decision as NFM
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function saveNFMVote(uint256 PullID, bool Vote) public returns (bool) {
        require(HasVoted[PullID][msg.sender] != 1, "AV"); //Check if voted
        require(
            INFM(address(_NFMController._getNFM())).balanceOf(msg.sender) >=
                100 * 10**18,
            "NB"
        ); //Check if 100NFM on balance

        HasVoted[PullID][msg.sender] = 1;
        VotesAll[PullID][msg.sender] = Vote;
        _NFMVotescounter[PullID][Vote] += 1;
        _AdressesVotescounter[PullID].push(msg.sender);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ saveAFTVote(uint256 PullID, bool Vote)
    Save my decision as AFT
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function saveAFTVote(uint256 PullID, bool Vote) public returns (bool) {
        (, uint256 Ref) = IAFT(address(_AFTController._getAFT()))
            ._returnTokenReference(msg.sender);
        require(Ref > 0, "FQ");
        require(AFThasVoted[PullID][Ref] != 1, "AV"); //Check if voted
        require(
            IAFT(address(_AFTController._getAFT())).balanceOf(msg.sender) > 0,
            "NB"
        ); //Check if 1AFT on balance

        AFThasVoted[PullID][Ref] = 1;
        AFTIdVotes[PullID][Ref] = Vote;
        AllAftcounts[PullID][Vote] += 1;
        _AFTVotescounter[PullID].push(Ref);
        _AFTAdressesVotescounter[PullID].push(msg.sender);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ createNFMPull(string calldata PullTitle,string calldata PullDescription,uint256 Days,uint256 VotingThema)
    Make pulls at level 3
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function createNFMPull(
        string calldata PullTitle,
        string calldata PullDescription,
        uint256 Days,
        uint256 VotingThema
    ) public returns (bool) {
        require(
            INFM(address(_NFMController._getNFM())).balanceOf(msg.sender) >=
                100 * 10**18,
            "NB"
        ); //Check if 100NFM on balance
        require(
            storePull(
                msg.sender,
                PullTitle,
                PullDescription,
                3,
                (block.timestamp + (3600 * 24 * Days)),
                VotingThema,
                true
            ) == true,
            "NS"
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ createContPull(string calldata PullTitle,string calldata PullDescription,uint256 Days,uint256 VotingThema)
    Make pulls at level 2
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function createContPull(
        string calldata PullTitle,
        string calldata PullDescription,
        uint256 Days,
        uint256 VotingThema
    ) public returns (bool) {
        require(
            INFMContributor(address(_NFMController._getContributor()))
                ._returnIsContributor(msg.sender) == true,
            "NA"
        );
        require(
            INFM(address(_NFMController._getNFM())).balanceOf(msg.sender) >=
                100 * 10**18,
            "NB"
        ); //Check if 100NFM on balance
        require(
            storePull(
                msg.sender,
                PullTitle,
                PullDescription,
                2,
                (block.timestamp + (3600 * 24 * Days)),
                VotingThema,
                true
            ) == true,
            "NS"
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ createAFTPull(string calldata PullTitle,string calldata PullDescription,uint256 Days,uint256 VotingThema)
    Make pulls at level 1
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function createAFTPull(
        string calldata PullTitle,
        string calldata PullDescription,
        uint256 Days,
        uint256 VotingThema
    ) public returns (bool) {
        require(
            IAFT(address(_AFTController._getAFT())).balanceOf(msg.sender) > 0,
            "NB"
        ); //Check if 1AFT on balance
        require(
            storePull(
                msg.sender,
                PullTitle,
                PullDescription,
                1,
                (block.timestamp + (3600 * 24 * Days)),
                VotingThema,
                true
            ) == true,
            "NS"
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ createAllPull(string calldata PullTitle,string calldata PullDescription,uint256 Days,uint256 VotingThema)
    Make pulls at level 4
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function createAllPull(
        string calldata PullTitle,
        string calldata PullDescription,
        uint256 Days,
        uint256 VotingThema
    ) public returns (bool) {
        require(
            IAFT(address(_AFTController._getAFT())).balanceOf(msg.sender) > 0,
            "NB"
        ); //Check if 1AFT on balance
        require(
            storePull(
                msg.sender,
                PullTitle,
                PullDescription,
                4,
                (block.timestamp + (3600 * 24 * Days)),
                VotingThema,
                true
            ) == true,
            "NS"
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ declinePull(uint256 PullID)
    This feature allows elections to be rejected if they do not have the success of the project in mind
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function declinePull(uint256 PullID) public returns (bool) {
        require(msg.sender == _Owner, "oO");
        gPulls[PullID].PullVoteapproved = false;
        return true;
    }
}