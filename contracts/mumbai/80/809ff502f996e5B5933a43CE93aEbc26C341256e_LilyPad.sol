// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title The LilyPad Backbone

/**********************************************************************
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 * ░░█████████████   █████████████████████████████████████████████░░░ *
 * ░███████████████   █████████████████████████████████████████████░░ *
 * ░░███████████████                              ████████████████░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 **********************************************************************/

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "base64-sol/base64.sol";

import "./interface/ILilyPad.sol";
import "./interface/IPondSBT.sol";

//TODO: OPTIMIZE GAS
//TODO: CHECK FOR CEI (CHECK, EFFECTS, INTERACTIONS)
contract LilyPad is Initializable, OwnableUpgradeable, ILilyPad {
    using StringsUpgradeable for uint256;

    //art Variables
    uint256 maxLevel;

    address public safeCaller;
    IPondSBT public sbtAddress;

    mapping(uint256 => Level) private levels;
    mapping(uint256 => EventType) private eventTypes;
    mapping(uint256 => Technology) private technologies;

    mapping(uint256 => TechBadge[]) private techBadges;
    mapping(uint256 => EventBadge[]) private eventBadges;

    mapping(address => Member) private addressToMember;
    mapping(address => uint256[]) private memberJourneys;

    mapping(uint256 => Journey) private journeys;
    mapping(uint256 => JourneyNode[]) private journeyNodes;

    mapping(uint256 => address) private tokenIdToAddress;

    //event variables
    mapping(uint256 => Event) private eventIdToEvent;

    /**
     *@notice initialize proxy
     *IN
     *@param _levels: initial level list
     *@param _eventTypes: initial event types list
     *OUT
     */
    function initialize(
        Level[] calldata _levels,
        EventType[] calldata _eventTypes,
        Technology[] calldata _technologies,
        address _safeCaller
    ) public initializer {
        for (uint256 idx = 0; idx < _levels.length; ++idx) {
            levels[_levels[idx].level] = _levels[idx];
            maxLevel = (maxLevel < _levels[idx].level) ? _levels[idx].level : maxLevel;
        }

        for (uint256 idx = 0; idx < _eventTypes.length; ++idx) {
            eventTypes[_eventTypes[idx].id] = _eventTypes[idx];
        }

        for (uint256 idx = 0; idx < _technologies.length; ++idx) {
            technologies[_technologies[idx].techId] = _technologies[idx];
        }

        __Ownable_init();

        safeCaller = _safeCaller;
    }

    function updateSafeCaller(address _newSafeCaller) external onlyOwner {
        safeCaller = _newSafeCaller;
    }

    function setSbtAddress(IPondSBT _newSbtAddress) external onlyOwner {
        sbtAddress = _newSbtAddress;
    }

    //MODIFIERS
    modifier onlyMember() {
        isPathChosen(msg.sender);
        _;
    }

    modifier onlySafeCaller(bytes32 message, bytes memory sig) {
        isSafeCaller(message, sig);
        _;
    }

    function isPathChosen(address _memberAddress) internal view {
        require(addressToMember[_memberAddress].pathChosen, "Path not Chosen");
    }

    function isSafeCaller(bytes32 message, bytes memory sig) internal view {
        require(recoverSigner(message, sig) == safeCaller, "I don't take orders from you");
    }

    function getAccoladesStr(Accolade[] calldata _accolades) internal view returns (string memory) {
        string memory _string;
        for (uint256 idx = 0; idx < _accolades.length; ++idx) {
            _string = string(
                abi.encodePacked(
                    _string,
                    StringsUpgradeable.toString(_accolades[idx].eventId),
                    StringsUpgradeable.toString(_accolades[idx].techId),
                    StringsUpgradeable.toString(_accolades[idx].level),
                    _accolades[idx].badge
                )
            );
        }

        return _string;
    }

    //LEVEL FUNCTIONS
    /**
     *@notice Create Level
     *IN
     *@param _levels: array with new levels to create. If level already exists, update it
     *OUT
     */
    function createLevel(Level[] calldata _levels) public onlyOwner {
        for (uint256 idx = 0; idx < _levels.length; ++idx) {
            if (levels[_levels[idx].level].level == 0) {
                levels[_levels[idx].level] = _levels[idx];
                maxLevel = (maxLevel < _levels[idx].level) ? _levels[idx].level : maxLevel;
            } else {
                levels[_levels[idx].level].xpInit = _levels[idx].xpInit;
                levels[_levels[idx].level].xpFin = _levels[idx].xpFin;
                levels[_levels[idx].level].image = _levels[idx].image;
            }
        }
    }

    /**
     *@notice Get Level by Id
     *IN
     *@param _levelId: Level Id to search for
     *OUT
     */
    function getLevel(uint256 _levelId) public view returns (Level memory) {
        return levels[_levelId];
    }

    //EVENT TYPE FUNCTIONS
    /**
     *@notice Create Event Type
     *IN
     *@param _eventTypes: array with new event types to create. If type already exists, update it
     *OUT
     */
    function createEventType(EventType[] calldata _eventTypes) public onlyOwner {
        for (uint256 idx = 0; idx < _eventTypes.length; ++idx) {
            if (eventTypes[_eventTypes[idx].id].id == 0) {
                eventTypes[_eventTypes[idx].id] = _eventTypes[idx];
            } else {
                eventTypes[_eventTypes[idx].id].name = _eventTypes[idx].name;
            }
        }
    }

    /**
     *@notice Get Event Type by Id
     *IN
     *@param _eventTypeId: Event Type Id to search for
     *OUT
     */
    function getEventType(uint256 _eventTypeId) public view returns (EventType memory) {
        return eventTypes[_eventTypeId];
    }

    //TECHNOLOGY FUNCTIONS
    /**
     *@notice Create Technology
     *IN
     *@param _technologies: array with new tech to keep track. If type already exists, update it
     *OUT
     */
    function createTechnology(
        Technology[] calldata _technologies,
        TechBadge[] calldata _badges
    ) public onlyOwner {
        for (uint256 idx = 0; idx < _technologies.length; ++idx) {
            if (technologies[_technologies[idx].techId].techId == 0) {
                technologies[_technologies[idx].techId] = _technologies[idx];
                //keep track of badges to techId
                uint256 badgesLength = _badges.length;
                delete techBadges[_technologies[idx].techId];

                for (uint256 idxBadges = 0; idxBadges < badgesLength; ++idxBadges) {
                    techBadges[_technologies[idx].techId].push(_badges[idxBadges]);
                }
            } else {
                technologies[_technologies[idx].techId].techName = _technologies[idx].techName;
                //keep track of badges to techId
                uint256 badgesLength = _badges.length;
                delete techBadges[_technologies[idx].techId];

                for (uint256 idxBadges = 0; idxBadges < badgesLength; ++idxBadges) {
                    techBadges[_technologies[idx].techId].push(_badges[idxBadges]);
                }
            }
        }
    }

    /**
     *@notice Get Technology by Id
     *IN
     *@param _technologyId: Technology Id to search for
     *OUT
     */
    function getTechnology(uint256 _technologyId) public view returns (Technology memory) {
        return technologies[_technologyId];
    }

    function submitBadge(
        uint256 _eventId,
        uint256 _techId,
        uint256 _level,
        bytes memory _badge
    ) external onlyOwner {
        if (_eventId > 0) {
            //its an event
            EventBadge[] memory badges = eventBadges[_eventId];
            uint256 arrayLength = badges.length;

            bool exists;
            uint256 idx = 0;

            for (idx = 0; idx < arrayLength; ++idx) {
                if (badges[idx].eventId == _eventId) {
                    exists = true;
                    break;
                }
            }

            if (!exists) eventBadges[_eventId].push(EventBadge({eventId: _eventId, badge: _badge}));
            else eventBadges[_eventId][idx].badge = _badge;
        } else {
            //its a tech
            TechBadge[] memory badges = techBadges[_techId];
            uint256 arrayLength = badges.length;

            bool exists;
            uint256 idx = 0;

            for (idx = 0; idx < arrayLength; ++idx) {
                if (badges[idx].level == _level && badges[idx].techId == _techId) {
                    exists = true;
                    break;
                }
            }

            if (!exists)
                techBadges[_techId].push(
                    TechBadge({techId: _techId, level: _level, badge: _badge})
                );
            else techBadges[_techId][idx].badge = _badge;
        }
    }

    //TECHNOLOGY FUNCTIONS
    //function submitBadge(
    //    EventBadge[] calldata _eventBadges,
    //    TechBadge[] calldata _techBadges
    //) external onlyOwner {
    //_submitEventBadges(_eventBadges);
    //    _submitTechBadges(_techBadges);
    //}

    /*function _submitEventBadges(EventBadge[] calldata _eventBadges) internal {
        uint256 eventBadgesLength = _eventBadges.length;

        for (uint256 idx = 0; idx < eventBadgesLength; ++idx) {
            //check if already exists
            EventBadge[] memory badges = eventBadges[_eventBadges[idx].eventId];
            uint256 arrayLength = badges.length;

            bool exists;
            for (uint256 idxImg = 0; idxImg <= arrayLength; ++idxImg) {
                if (
                    keccak256(abi.encodePacked(badges[idx].badge)) ==
                    keccak256(abi.encodePacked(_eventBadges[idx].badge))
                ) {
                    exists = true;
                    break;
                }
            }

            if (!exists)
                eventBadges[_eventBadges[idx].eventId].push(
                    EventBadge({eventId: _eventBadges[idx].eventId, badge: _eventBadges[idx].badge})
                );
        }
    }

    function _submitTechBadges(TechBadge[] calldata _techBadges) internal {
        uint256 techBadgesLength = _techBadges.length;

        for (uint256 idx = 0; idx < techBadgesLength; ++idx) {
            //check if already exists
            TechBadge[] memory badges = techBadges[_techBadges[idx].techId];
            uint256 arrayLength = badges.length;

            revert(StringsUpgradeable.toString(arrayLength));
            bool exists;
            for (uint256 idxImg = 0; idxImg <= arrayLength; ++idxImg) {
                if (
                    badges[idx].level == _techBadges[idx].level &&
                    keccak256(abi.encodePacked(badges[idx].badge)) ==
                    keccak256(abi.encodePacked(_techBadges[idx].badge))
                ) {
                    exists = true;
                    break;
                }
            }

            if (!exists)
                techBadges[_techBadges[idx].techId].push(
                    TechBadge({
                        techId: _techBadges[idx].techId,
                        level: _techBadges[idx].level,
                        badge: _techBadges[idx].badge
                    })
                );
        }
    }*/

    /**
     *@notice Get Technology badge by level
     *IN
     *@param _technologyId: Technology Id to search for badge
     *@param level: level to search for badge
     *OUT
     */
    function getTechBadge(
        uint256 _technologyId,
        uint256 level
    ) public view returns (TechBadge memory) {
        TechBadge[] memory _badges = techBadges[_technologyId];

        uint256 badgesLength = _badges.length;
        for (uint256 idx = 0; idx < badgesLength; ++idx) {
            if (_badges[idx].level == level) return _badges[idx];
        }

        return TechBadge({techId: 0, level: 0, badge: new bytes(0)});
    }

    //COURSE FUNCTIONS
    /**
     *@notice Submite a Course or Event to be featured in the Lilypad Platform
     *IN
     *@param _eventTypeId: event type id
     *@param _eventName: event name byteslike
     *@param _xp: xp given by course completion
     *@param _technologies: list of accolades of the event
     *@param _sig: signatura from safeCaller
     *OUT
     */
    function submitEvent(
        uint256 _eventId,
        uint256 _eventTypeId,
        bytes calldata _eventName,
        uint256 _xp,
        uint256 _level,
        uint256[] calldata _technologies,
        bytes memory _sig
    )
        public
        onlySafeCaller(
            prefixed(
                keccak256(
                    abi.encodePacked(_eventId, _eventTypeId, _eventName, _xp, _level, _technologies)
                )
            ),
            _sig
        )
    {
        require(eventIdToEvent[_eventId].id <= 0, "Event already created");

        eventIdToEvent[_eventId].id = _eventId;
        eventIdToEvent[_eventId].eventTypeId = _eventTypeId;
        eventIdToEvent[_eventId].xp = _xp;
        eventIdToEvent[_eventId].eventName = _eventName;
        eventIdToEvent[_eventId].level = _level;

        for (uint256 idx = 0; idx < _technologies.length; ++idx) {
            if (technologies[_technologies[idx]].techId <= 0)
                revert TechNotFound(_technologies[idx]);

            eventIdToEvent[_eventId].technologies.push(_technologies[idx]);
        }

        emit EventSubmited(msg.sender, _eventId, _eventTypeId, _eventName);
    }

    /**
     *@notice Retrieve event object by its id
     *IN
     *@param _id: event id
     *OUT
     *@return eventTypeId type of event
     *@return xp given by course completion or event participation
     *@return eventTechs list of accolades of the event
     */
    function getEvent(
        uint256 _id
    ) public view returns (uint256 eventTypeId, uint256 xp, Technology[] memory eventTechs) {
        Event memory _event = eventIdToEvent[_id];

        uint256 eventTechLength = _event.technologies.length;
        eventTechs = new Technology[](_event.technologies.length);

        for (uint256 idx = 0; idx < eventTechLength; ++idx) {
            eventTechs[idx] = technologies[_event.technologies[idx]];
        }

        return (_event.eventTypeId, _event.xp, eventTechs);
    }

    /**
     *@dev The update clear the accolades list and recreate with the accolades passed to the function
     *@notice Update event attributes with given id
     *IN
     *@param _id: event id
     *@param _eventTypeId: event type id
     *@param _xp: xp given by event completion or event participation
     *@param _technologies: list of technologies of event
     *@param _sig: safeCaller signature
     *OUT
     */
    function updateEvent(
        uint256 _id,
        uint256 _eventTypeId,
        bytes memory _eventName,
        uint256 _xp,
        uint256[] calldata _technologies,
        bytes memory _sig
    )
        public
        onlySafeCaller(
            prefixed(keccak256(abi.encodePacked(_id, _eventTypeId, _xp, _technologies))),
            _sig
        )
    {
        eventIdToEvent[_id].xp = _xp;
        eventIdToEvent[_id].eventTypeId = _eventTypeId;
        eventIdToEvent[_id].eventName = _eventName;

        delete eventIdToEvent[_id].technologies;

        uint256 eventTechLength = _technologies.length;

        for (uint256 idx = 0; idx < eventTechLength; ++idx) {
            eventIdToEvent[_id].technologies.push(_technologies[idx]);
        }

        //emit EventUpdated(msg.sender, _id, _eventTypeId, _eventName, _xp, _accolades);
    }

    // MEMBER FUNCTIONS
    /**
     *@notice Return member object associated to given address
     *IN
     *@param _memberAddress: member address
     *OUT
     */
    function getMember(
        address _memberAddress
    )
        public
        view
        override
        returns (
            bool pathChosen,
            uint256 xp,
            uint256 level,
            bool DAO,
            uint256 tokenId,
            uint256[] memory completedEvents,
            Accolade[] memory badges
        )
    {
        return (
            addressToMember[_memberAddress].pathChosen,
            addressToMember[_memberAddress].xp,
            getMemberLevel(_memberAddress),
            addressToMember[_memberAddress].DAO,
            addressToMember[_memberAddress].tokenId,
            addressToMember[_memberAddress].completedEvents,
            addressToMember[_memberAddress].badges
        );
    }

    /**
     *@notice Insert new Member that chosen to follow The Path
     *@dev in the _badges accolade object there is no need to send the badge data. Just eventId and accoladeTitle
     *IN
     *@param _initialXp: member initial xp
     *@param _completedEvents: array of complete events ids
     *@param _badges: array of courses ids with earned badges
     *OUT
     */
    function createMember(
        address _member,
        uint256 _initialXp,
        uint256[] calldata _completedEvents,
        Accolade[] calldata _badges,
        bytes memory _sig
    )
        public
        onlySafeCaller(
            prefixed(
                keccak256(
                    abi.encodePacked(
                        _member,
                        _initialXp,
                        _completedEvents,
                        getAccoladesStr(_badges)
                    )
                )
            ),
            _sig
        )
    {
        _createMember(_member, _initialXp, _completedEvents, _badges);
    }

    // MEMBER FUNCTIONS
    /**
     *@notice Insert new Member that chosen to follow The Path
     *@dev in the _badges accolade object there is no need to send the badge data. Just eventId and accoladeTitle
     *IN
     *@param _initialXp: member initial xp
     *@param _completedEvents: array of complete events ids
     *@param _badges: array of accolades , byteslike, earned by member
     *OUT
     */
    function _createMember(
        address _memberAddress,
        uint256 _initialXp,
        uint256[] memory _completedEvents,
        Accolade[] memory _badges
    ) internal {
        require(!addressToMember[_memberAddress].pathChosen, "Path Already Chosen");

        addressToMember[_memberAddress].pathChosen = true;
        addressToMember[_memberAddress].xp = _initialXp;
        addressToMember[_memberAddress].DAO = true;
        addressToMember[_memberAddress].tokenId = 0;
        for (uint256 idx = 0; idx < _completedEvents.length; ++idx) {
            addressToMember[_memberAddress].completedEvents.push(_completedEvents[idx]);
        }

        for (uint256 idx = 0; idx < _badges.length; ++idx) {
            addressToMember[_memberAddress].badges.push(_badges[idx]);
        }

        updateJourney(_memberAddress);
    }

    /**
     *@notice Update all of Member data
     *IN
     *@param _memberAddress: member address
     *@param _dao: dao?
     *@param _xp: xp owned by member
     *@param _completedEvents: array of complete courses ids
     *@param _badges: array of courses ids with earned badges
     *OUT
     */
    function updateMember(
        address _memberAddress,
        bool _dao,
        uint256 _xp,
        uint256[] calldata _completedEvents,
        Accolade[] calldata _badges,
        bytes memory _sig
    )
        public
        onlySafeCaller(
            prefixed(
                keccak256(
                    abi.encodePacked(
                        _memberAddress,
                        _dao,
                        _xp,
                        _completedEvents,
                        getAccoladesStr(_badges)
                    )
                )
            ),
            _sig
        )
    {
        //mapping(address => Member) storage _addressToMember = addressToMember;
        if (!addressToMember[_memberAddress].pathChosen) {
            _createMember(_memberAddress, _xp, _completedEvents, _badges);
        } else {
            addressToMember[_memberAddress].pathChosen = addressToMember[_memberAddress].pathChosen;
            addressToMember[_memberAddress].xp = _xp;
            addressToMember[_memberAddress].DAO = _dao;
            addressToMember[_memberAddress].tokenId = addressToMember[_memberAddress].tokenId;

            delete addressToMember[_memberAddress].completedEvents;

            uint256 eventsLength = _completedEvents.length;
            uint256 badgesLength = _badges.length;

            for (uint256 idx = 0; idx < eventsLength; ++idx) {
                addressToMember[_memberAddress].completedEvents.push(_completedEvents[idx]);
            }

            for (uint256 idx = 0; idx < badgesLength; ++idx) {
                if (
                    !badgeEarned(
                        _memberAddress,
                        _badges[idx].eventId,
                        _badges[idx].techId,
                        _badges[idx].level
                    )
                ) {
                    _awardBadge(_memberAddress, _badges[idx], false);
                }
            }

            updateJourney(_memberAddress);
        }
    }

    // MEMBER FUNCTIONS
    /**
     *@notice Block Member from DAO
     *@dev blocked members cant vote nor propose
     *IN
     *@param _memberAddress: member address
     *@param _status: DAO access status. False: blocked;
     *OUT
     */
    function _memberDaoStatus(address _memberAddress, bool _status) internal {
        require(!addressToMember[_memberAddress].pathChosen, "Path Already Chosen");
        //TODO: emit events
        addressToMember[_memberAddress].DAO = _status;
    }

    /**
     *@notice update Member event completion
     *IN
     *@param _member: member address
     *@param _eventId: id of completed event
     *OUT
     */
    function completeEvent(
        address _member,
        uint256 _eventId,
        bytes memory _sig
    ) public onlySafeCaller(prefixed(keccak256(abi.encodePacked(_member, _eventId))), _sig) {
        //TODO: make it batch prepared
        if (!addressToMember[_member].pathChosen) revert NotAFrog(_member);

        if (!completedEvent(_member, _eventId)) _completeEvent(_member, _eventId, true);
    }

    /**
     *@notice update Member event completion
     *@dev this function dont check if course was already completed, since it is checked on the public function. Be aware!
     *@dev _update journey variable serves for batch update when we dont want to update journey every single course completion
     *IN
     *@param _member: member address
     *@param _eventId: id of event
     *OUT
     */
    function _completeEvent(address _member, uint256 _eventId, bool _updateJourney) internal {
        //check member current level
        uint256 currentLevel = getMemberLevel(_member);

        Event memory _event = eventIdToEvent[_eventId];

        addressToMember[_member].completedEvents.push(_eventId);
        addressToMember[_member].xp += _event.xp;

        emit EventCompleted(_member, _eventId, string(abi.encodePacked(_event.eventName)));
        //check member new level
        uint256 newLevel = getMemberLevel(_member);

        if (newLevel > currentLevel)
            emit LevelReached(_member, addressToMember[_member].xp, newLevel);

        //award badges
        uint256 eventBadgesLenght = eventBadges[_eventId].length;
        uint256 techBadgesLenght = _event.technologies.length;

        //award event badges
        for (uint256 idx = 0; idx < eventBadgesLenght; ++idx) {
            Accolade memory badge = Accolade({
                eventId: _eventId,
                techId: 0,
                level: _event.level,
                badge: eventBadges[_eventId][idx].badge
            });

            _awardBadge(_member, badge, false);
        }

        //award tech badges
        for (uint256 idx = 0; idx < techBadgesLenght; ++idx) {
            uint256 _level = _event.level;

            while (_level > 0) {
                TechBadge memory techBadge = getTechBadge(_event.technologies[idx], _level);

                if (techBadge.techId > 0) {
                    Accolade memory badge = Accolade({
                        eventId: 0,
                        techId: techBadge.techId,
                        level: _level,
                        badge: techBadge.badge
                    });

                    _awardBadge(_member, badge, false);
                }

                --_level;
            }
        }

        //update journeys
        if (_updateJourney) updateJourney(_member);
    }

    /**
     *@notice Award badge to member for course completion or event participation.
     *@dev in the _badges accolade object there is no need to send the badge image data. Just eventId and accoladeTitle
     *IN
     *@param _member: member address
     *@param _techId: id of technology
     *@param _level: level of earning
     *OUT
     */
    function getAwardedBadge(
        address _member,
        uint256 _eventId,
        uint256 _techId,
        uint256 _level
    ) public view returns (Accolade memory, uint256 badgeIndex) {
        Accolade[] memory memberBadges = addressToMember[_member].badges;
        uint256 badgesLength = memberBadges.length;

        for (uint256 idx = 0; idx < badgesLength; ++idx) {
            if (
                (_techId > 0 &&
                    memberBadges[idx].techId == _techId &&
                    memberBadges[idx].level == _level) ||
                (_eventId > 0 && memberBadges[idx].eventId == _eventId)
            ) return (memberBadges[idx], idx);
        }

        return (Accolade({eventId: 0, techId: 0, level: 0, badge: new bytes(0)}), 0);
    }

    /**
     *@notice Award badge to member for course completion or event participation.
     *@dev in the _badges accolade object there is no need to send the badge image data. Just eventId and accoladeTitle
     *IN
     *@param _member: member address
     *@param _badges: id of event
     *OUT
     */
    function awardBadge(
        address _member,
        Accolade[] calldata _badges,
        bytes calldata _sig
    )
        public
        onlySafeCaller(
            prefixed(keccak256(abi.encodePacked(_member, getAccoladesStr(_badges)))),
            _sig
        )
    {
        for (uint256 idx = 0; idx < _badges.length; ++idx) {
            //if (
            //    !badgeEarned(_member, _badges[idx].eventId, _badges[idx].techId, _badges[idx].level)
            //)
            _awardBadge(_member, _badges[idx], true);
        }
    }

    /**
     *@notice Award badge to member for course completion or event participation.
     *@dev this function dont check if badge was already earned, since it is checked on the public function. Be aware!
     *@dev _update journey variable serves for batch update when we dont want to update journey every single badge award
     *IN
     *@param _member: member address
     *@param _accolade: accolade object
     *OUT
     */
    function _awardBadge(address _member, Accolade memory _accolade, bool _updateJourney) internal {
        if (!badgeEarned(_member, _accolade.eventId, _accolade.techId, _accolade.level)) {
            addressToMember[_member].badges.push(
                Accolade({
                    eventId: _accolade.eventId,
                    techId: _accolade.techId,
                    level: _accolade.level,
                    //get the current badge art for immutability purpose
                    badge: _accolade.badge
                })
            );

            emit BadgeEarned(_member, _accolade.eventId, _accolade.techId, _accolade.level);
        } /* else {
            (Accolade memory existingAccolade, uint256 idx) = getAwardedBadge(
                _member,
                _accolade.eventId,
                _accolade.techId,
                _accolade.level
            );

            addressToMember[_member].badges[idx]
                if (!arrayContains(existingAccolade.eventId, _accolade.eventId[eventIdx])) {
                    addressToMember[_member].badges[idx].eventsId.push(
                        _accolade.eventsId[eventIdx]
                    );
                    emit BadgeEarned(
                        _member,
                        _accolade.eventsId[eventIdx],
                        _accolade.techId,
                        _accolade.level
                    );
                }

            uint256 eventsLength = _accolade.eventsId.length;

            for (uint256 eventIdx = 0; eventIdx < eventsLength; ++eventIdx) {
                if (!arrayContains(existingAccolade.eventsId, _accolade.eventsId[eventIdx])) {
                    addressToMember[_member].badges[idx].eventsId.push(
                        _accolade.eventsId[eventIdx]
                    );
                    emit BadgeEarned(
                        _member,
                        _accolade.eventsId[eventIdx],
                        _accolade.techId,
                        _accolade.level
                    );
                }
            }
        }*/

        //update journeys
        if (_updateJourney) updateJourney(_member);
    }

    /**
     *@notice Check if course was completed
     *IN
     *@param _member: member address
     *@param _eventId: id of event
     *OUT
     *@return bool: if event was already completed
     */
    function completedEvent(address _member, uint256 _eventId) public view returns (bool) {
        for (uint256 idx = 0; idx < addressToMember[_member].completedEvents.length; ++idx) {
            if (addressToMember[_member].completedEvents[idx] == _eventId) return true;
        }

        return false;
    }

    /**
     *@notice Check if badge was already earned
     *IN
     *@param _member: member address
     *@param _techId: id of tech
     *OUT
     *@return bool: if badge was already completed
     */
    function badgeEarned(
        address _member,
        uint256 _eventId,
        uint256 _techId,
        uint256 _level
    ) public view returns (bool) {
        Accolade[] memory list = addressToMember[_member].badges;

        uint256 badgesLength = list.length;

        for (uint256 idx = 0; idx < badgesLength; ++idx) {
            if (_techId > 0 && list[idx].techId == _techId && list[idx].level == _level)
                return true;
            else if (_eventId > 0 && list[idx].eventId == _eventId) return true;
        }

        return false;
    }

    /**
     *@notice Check if all badges of event were already earned
     *IN
     *@param _member: member address
     *@param _eventId: id of event
     *OUT
     *@return bool: if all badges were already earned
     */
    function allBadgesEarned(address _member, uint256 _eventId) internal view returns (bool) {
        Event memory _event = eventIdToEvent[_eventId];

        uint256 length = _event.technologies.length;

        for (uint256 idx = 0; idx < length; ++idx) {
            TechBadge[] memory _techBadges = techBadges[_event.technologies[idx]];
            for (uint256 badgeIdx = 0; badgeIdx < _techBadges.length; ++badgeIdx) {
                if (
                    !badgeEarned(
                        _member,
                        0,
                        _techBadges[badgeIdx].techId,
                        _techBadges[badgeIdx].level
                    )
                ) return false;
            }
        }
        return true;
    }

    /**
     *@notice Mint SBT
     *IN
     *@param _memberAddress: member address
     *OUT
     */
    function mintTokenForMember(address _memberAddress) public payable {
        require(addressToMember[_memberAddress].tokenId == 0, "SBT already defined!");

        try sbtAddress.takeFirstSteps{value: msg.value}(_memberAddress) returns (uint256 tokenId) {
            addressToMember[_memberAddress].tokenId = tokenId;
            tokenIdToAddress[tokenId] = _memberAddress;
        } catch Error(string memory err) {
            revert(err);
        }
    }

    /**
     *@notice Return member object associated to given SBT tokenId
     *IN
     *@param _tokenId: tokenId to look up
     *OUT
     *memberAddress: address of the member
     *pathChosen: if member chosed the path
     *name: name of the member
     *level: level of member
     *DAO: if member participate in DAO
     *tokenId: tokenId owned by the member
     *completedEvents: array of completed events by the member
     *badges: array of badges earned by the member
     */
    function getMemberByTokenId(
        uint256 _tokenId
    )
        public
        view
        returns (
            address memberAddress,
            bool pathChosen,
            uint256 xp,
            uint256 level,
            bool DAO,
            uint256 tokenId,
            uint256[] memory completedEvents,
            Accolade[] memory badges
        )
    {
        Member memory _member = addressToMember[tokenIdToAddress[_tokenId]];
        return (
            tokenIdToAddress[_tokenId],
            _member.pathChosen,
            _member.xp,
            getMemberLevel(tokenIdToAddress[_tokenId]),
            _member.DAO,
            _member.tokenId,
            _member.completedEvents,
            _member.badges
        );
    }

    /**
     *@notice Return SBT tokenId owned by member associated to given address
     *IN
     *@param _memberAddress: tokenId owned by member associated to given address
     *OUT
     *@return uint256: tokenId found (0 equals no token)
     */
    function getTokenId(address _memberAddress) public view returns (uint256) {
        return addressToMember[_memberAddress].tokenId;
    }

    /**
     *@notice Get current Member Level
     *IN
     *@param _memberAddress: tokenId owned by member associated to given address
     *OUT
     *@return uint256: member level
     */
    function getMemberLevel(address _memberAddress) public view returns (uint256) {
        uint256 _maxLevel = maxLevel;
        Member memory member = addressToMember[_memberAddress];

        for (uint256 idx = 1; idx <= _maxLevel; ++idx) {
            Level memory level = levels[idx];

            if (member.xp >= level.xpInit && member.xp <= level.xpFin) {
                return level.level;
            }
        }
        return 0;
    }

    //JOURNEY FUNCTIONS
    function createJourney(
        uint256 _journeyId,
        bytes calldata _name,
        bool _badgeObligatory,
        uint256[] calldata _eventId
    ) external onlyMember returns (Journey memory) {
        (bool _journeyExists, Journey memory _journeyFound) = journeyExists(msg.sender, _eventId);

        if (_journeyExists) return _journeyFound;
        else {
            journeys[_journeyId] = Journey({
                id: _journeyId,
                member: msg.sender,
                name: _name,
                done: false,
                badgeObligatory: _badgeObligatory
            });

            uint256 eventLength = _eventId.length;

            for (uint256 nodeIdx = 0; nodeIdx < eventLength; ++nodeIdx) {
                bool journeyStepCompleted;
                if (journeys[_journeyId].badgeObligatory)
                    journeyStepCompleted = allBadgesEarned(msg.sender, _eventId[nodeIdx]);
                else journeyStepCompleted = completedEvent(msg.sender, _eventId[nodeIdx]);

                journeyNodes[_journeyId].push(
                    JourneyNode({
                        step: nodeIdx + 1,
                        eventId: _eventId[nodeIdx],
                        done: completedEvent(msg.sender, _eventId[nodeIdx])
                    })
                );
            }

            journeys[_journeyId].done = journeyCompleted(_journeyId);

            return journeys[_journeyId];
        }
    }

    function updateJourney(
        uint256 _journeyId,
        bytes memory _name,
        bool _badgeObligatory,
        uint256[] memory _eventsId
    ) external onlyMember returns (Journey memory) {
        require(journeys[_journeyId].member != address(0), "Journey not found");
        require(journeys[_journeyId].member == msg.sender, "Journey not found");

        delete journeyNodes[_journeyId];

        journeys[_journeyId].name = _name;
        journeys[_journeyId].badgeObligatory = _badgeObligatory;

        for (uint256 nodeIdx = 0; nodeIdx < _eventsId.length; ++nodeIdx) {
            bool journeyStepCompleted;
            if (journeys[_journeyId].badgeObligatory)
                journeyStepCompleted = allBadgesEarned(msg.sender, _eventsId[nodeIdx]);
            else journeyStepCompleted = completedEvent(msg.sender, _eventsId[nodeIdx]);

            journeyNodes[_journeyId].push(
                JourneyNode({
                    step: nodeIdx + 1,
                    eventId: _eventsId[nodeIdx],
                    done: journeyStepCompleted
                })
            );
        }

        journeys[_journeyId].done = journeyCompleted(_journeyId);

        return journeys[_journeyId];
    }

    function abandonJourney(uint256 _journeyId) public onlyMember returns (Journey memory) {
        require(journeys[_journeyId].member != address(0), "Journey not found");
        require(journeys[_journeyId].member == msg.sender, "Journey not found");

        delete journeyNodes[_journeyId];

        journeys[_journeyId].done = true;

        return journeys[_journeyId];
    }

    function journeyExists(
        address _memberAddress,
        uint256[] memory _eventsId
    ) private view returns (bool exists, Journey memory journey) {
        Journey memory _journey;
        for (
            uint256 journeyIdx = 0;
            journeyIdx < memberJourneys[_memberAddress].length;
            ++journeyIdx
        ) {
            bool _same = true;
            uint256 journeyId = memberJourneys[_memberAddress][journeyIdx];
            for (uint256 nodeIdx = 0; nodeIdx < journeyNodes[journeyId].length; ++nodeIdx) {
                if (_eventsId[nodeIdx] != journeyNodes[journeyId][nodeIdx].eventId) {
                    _same = false;
                    continue;
                }
                _journey = journeys[journeyId];
            }
            if (_same) {
                return (true, _journey);
            }
        }

        return (false, _journey);
    }

    function journeyCompleted(uint256 _journeyId) private view returns (bool) {
        for (uint256 nodeIdx = 0; nodeIdx < journeyNodes[_journeyId].length; ++nodeIdx) {
            if (!journeyNodes[_journeyId][nodeIdx].done) return false;
        }

        return true;
    }

    function updateJourney(address _memberAddress) internal {
        for (
            uint256 journeyIdx = 0;
            journeyIdx < memberJourneys[_memberAddress].length;
            ++journeyIdx
        ) {
            uint256 journeyId = memberJourneys[_memberAddress][journeyIdx];

            if (journeys[journeyId].done) continue;

            bool havePendingSteps;

            for (uint256 nodeIdx = 0; nodeIdx < journeyNodes[journeyId].length; ++nodeIdx) {
                if (!journeyNodes[journeyId][nodeIdx].done)
                    if (journeys[journeyId].badgeObligatory)
                        journeyNodes[journeyId][nodeIdx].done = allBadgesEarned(
                            _memberAddress,
                            journeyNodes[journeyId][nodeIdx].eventId
                        );
                    else
                        journeyNodes[journeyId][nodeIdx].done = completedEvent(
                            _memberAddress,
                            journeyNodes[journeyId][nodeIdx].eventId
                        );

                if (!journeyNodes[journeyId][nodeIdx].done) havePendingSteps = true;
            }

            if (!havePendingSteps) journeys[journeyId].done = true;
        }
    }

    /**
     *@notice Burn member records. Only SBT contract can call it after execute the token burn
     *IN
     *@param member: address of member to burn
     *OUT
     */
    function burnBabeBurn(address member) external override {
        require(
            msg.sender == address(sbtAddress),
            "LilyPad::Only SBT Contract can call menbership burn"
        );

        addressToMember[member].pathChosen = false;
        addressToMember[member].xp = 0;
        addressToMember[member].tokenId = 0;

        delete addressToMember[member].completedEvents;
        delete addressToMember[member].badges;

        emit MemberBurned(member);
    }

    function constructTokenUri(
        uint256 _tokenId,
        string memory _baseUri
    ) external view override returns (string memory) {
        (
            address _memberAddress,
            ,
            ,
            ,
            ,
            ,
            uint256[] memory _completedEvents,
            Accolade[] memory _badges
        ) = getMemberByTokenId(_tokenId);
        require(_tokenId > 0, "Invalid Member/Token data");

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"PondSBT ',
                                _tokenId.toString(),
                                '", "description":"Part of the Soul of ',
                                StringsUpgradeable.toHexString(uint160(_memberAddress), 20),
                                '","image": "',
                                string(
                                    abi.encodePacked(
                                        _baseUri,
                                        levels[getMemberLevel(_memberAddress)].image
                                    )
                                ),
                                '",',
                                buildAttributes(getMemberLevel(_memberAddress), _completedEvents),
                                ",",
                                buildBadges(_badges, _baseUri),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function buildAttributes(
        uint256 _level,
        uint256[] memory _completedEvents
    ) internal view returns (string memory) {
        string memory _attributes = '"attributes": [';
        _attributes = string(
            abi.encodePacked(
                _attributes,
                '{ "trait_type":"Level", "value": ',
                _level.toString(),
                "}"
            )
        );
        for (uint256 idx = 0; idx < _completedEvents.length; ++idx) {
            _attributes = string(abi.encodePacked(_attributes, ',{ "trait_type":"'));

            _attributes = string(
                abi.encodePacked(
                    _attributes,
                    eventTypes[eventIdToEvent[_completedEvents[idx]].eventTypeId].name
                )
            );

            _attributes = string(abi.encodePacked(_attributes, '", "value": "'));
            _attributes = string(
                abi.encodePacked(_attributes, eventIdToEvent[_completedEvents[idx]].eventName)
            );
            _attributes = string(abi.encodePacked(_attributes, '"}'));
        }

        _attributes = string(abi.encodePacked(_attributes, "]"));

        return _attributes;
    }

    function buildBadges(
        Accolade[] memory _badges,
        string memory _baseUri
    ) internal view returns (string memory) {
        string memory _badgesUri = '"badges": [';
        for (uint256 idx = 0; idx < _badges.length; ++idx) {
            if (idx > 0)
                _badgesUri = string(abi.encodePacked(_badgesUri, ',{ "trait_type":"BADGE"'));
            else _badgesUri = string(abi.encodePacked(_badgesUri, '{ "trait_type":"BADGE"'));

            //_badgesUri = string(abi.encodePacked(_badgesUri, '{ "trait_type":"BADGE"'));

            if (_badges[idx].techId > 0) {
                Technology memory tech = getTechnology(_badges[idx].techId);
                //TechBadge memory techBadge = getTechBadge(_badges[idx].techId, _badges[idx].level);

                _badgesUri = string(abi.encodePacked(_badgesUri, ', "value": "'));
                _badgesUri = string(
                    abi.encodePacked(
                        _badgesUri,
                        tech.techName,
                        "(Level ",
                        StringsUpgradeable.toString(_badges[idx].level),
                        ")"
                    )
                );
                _badgesUri = string(abi.encodePacked(_badgesUri, '", "image": "'));
                _badgesUri = string(abi.encodePacked(_badgesUri, _baseUri, _badges[idx].badge));

                _badgesUri = string(abi.encodePacked(_badgesUri, '"}'));
            }

            if (_badges[idx].eventId > 0) {
                _badgesUri = string(abi.encodePacked(_badgesUri, ', "value": "'));
                _badgesUri = string(
                    abi.encodePacked(_badgesUri, eventIdToEvent[_badges[idx].eventId].eventName)
                );
                _badgesUri = string(abi.encodePacked(_badgesUri, '", "image": "'));
                _badgesUri = string(abi.encodePacked(_badgesUri, _baseUri, _badges[idx].badge));

                _badgesUri = string(abi.encodePacked(_badgesUri, '"}'));
            }
        }

        _badgesUri = string(abi.encodePacked(_badgesUri, "]"));

        return _badgesUri;
    }

    //SECURITY FUNCTIONS

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    function splitSignature(bytes memory _sig) internal pure returns (uint8, bytes32, bytes32) {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 _message, bytes memory _sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_sig);

        return ecrecover(_message, v, r, s);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Main Contract

pragma solidity ^0.8.4;

/**********************************************************************
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 * ░░█████████████   █████████████████████████████████████████████░░░ *
 * ░███████████████   █████████████████████████████████████████████░░ *
 * ░░███████████████                              ████████████████░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 **********************************************************************/

import "./IPondSBT.sol";

interface ILilyPad {
    error TechNotFound(uint256 techId);
    error NotAFrog(address _address);

    event EventSubmited(address owner, uint256 eventId, uint256 eventTypeId, bytes eventName);

    event EventCompleted(address member, uint256 eventId, string eventName);
    event BadgeEarned(address member, uint256 eventId, uint256 techId, uint256 level);
    event BadgesEarned(address member, uint256[] eventId, uint256 techId, uint256 level);

    event LevelReached(address member, uint256 currentXp, uint256 level);

    event MemberBurned(address member);

    struct Level {
        uint256 level;
        uint256 xpInit;
        uint256 xpFin;
        bytes image;
    }

    struct TechBadge {
        uint256 techId;
        uint256 level;
        bytes badge;
    }

    struct EventBadge {
        uint256 eventId;
        bytes badge;
    }

    struct Technology {
        uint256 techId;
        bytes techName;
    }

    struct Accolade {
        uint256 eventId;
        uint256 techId;
        uint256 level;
        bytes badge;
    }

    struct Member {
        bool pathChosen;
        uint256 xp;
        bool DAO;
        uint256 tokenId;
        uint256[] completedEvents;
        Accolade[] badges;
    }

    struct EventType {
        uint256 id;
        bytes name;
    }

    struct Event {
        uint256 id;
        uint256 eventTypeId;
        bytes eventName;
        uint256 level;
        uint256 xp;
        uint256[] technologies;
    }

    struct Journey {
        uint256 id;
        address member;
        bytes name;
        bool done;
        bool badgeObligatory;
    }

    struct JourneyNode {
        uint256 step;
        uint256 eventId;
        bool done;
    }

    function getMember(
        address memberAddress
    )
        external
        view
        returns (
            bool pathChosen,
            uint256 xp,
            uint256 level,
            bool DAO,
            uint256 tokenId,
            uint256[] memory completedEvents,
            Accolade[] memory badges
        );

    function getEvent(
        uint256 eventId
    ) external view returns (uint256 eventTypeId, uint256 xp, Technology[] memory eventTechs);

    function completedEvent(address _member, uint256 _eventId) external view returns (bool);

    function badgeEarned(
        address _member,
        uint256 _eventId,
        uint256 _techId,
        uint256 _level
    ) external view returns (bool);

    function constructTokenUri(
        uint256 _tokenId,
        string memory _baseUri
    ) external view returns (string memory);

    function burnBabeBurn(address member) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for POND SBT token

pragma solidity ^0.8.4;

/**********************************************************************
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██      ██ ███ ██████████████████ ███ ██      ██ ███ ░░░░░ *
 * ░░░░███ ██████████ ███ ██████████████████ ███ ██████████ ███ ░░░░░ *
 * ░░░░██████████████████ ██████████████████ ██████████████████ ░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░░░████████████████████  ██████████  ███████████████████░░░░░░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 * ░░█████████████   █████████████████████████████████████████████░░░ *
 * ░███████████████   █████████████████████████████████████████████░░ *
 * ░░███████████████                              ████████████████░░░ *
 * ░░░███████████████████████████████████████████████████████████░░░░ *
 **********************************************************************/

interface IPondSBT {
    event SoulBounded(address soulOwner, uint256 tokenId);
    event MintFeeUpdated(uint256 oldFee, uint256 newFee);

    function takeFirstSteps(address _member) external payable returns (uint256);
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