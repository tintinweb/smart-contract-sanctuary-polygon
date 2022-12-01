/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

/*

       ▄▄▄▄███▄▄▄▄    ▄█  ███▄▄▄▄       ███           ▄██████▄     ▄████████      ████████▄     ▄████████    ▄████████     ███      ▄█  ███▄▄▄▄   ▄██   ▄
     ▄██▀▀▀███▀▀▀██▄ ███  ███▀▀▀██▄ ▀█████████▄      ███    ███   ███    ███      ███   ▀███   ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄ ███   ██▄
     ███   ███   ███ ███▌ ███   ███    ▀███▀▀██      ███    ███   ███    █▀       ███    ███   ███    █▀    ███    █▀     ▀███▀▀██ ███▌ ███   ███ ███▄▄▄███
     ███   ███   ███ ███▌ ███   ███     ███   ▀      ███    ███  ▄███▄▄▄          ███    ███  ▄███▄▄▄       ███            ███   ▀ ███▌ ███   ███ ▀▀▀▀▀▀███
     ███   ███   ███ ███▌ ███   ███     ███          ███    ███ ▀▀███▀▀▀          ███    ███ ▀▀███▀▀▀     ▀███████████     ███     ███▌ ███   ███ ▄██   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███    ███   ███    █▄           ███     ███     ███  ███   ███ ███   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███   ▄███   ███    ███    ▄█    ███     ███     ███  ███   ███ ███   ███
      ▀█   ███   █▀  █▀    ▀█   █▀     ▄████▀         ▀██████▀    ███             ████████▀    ██████████  ▄████████▀     ▄████▀   █▀    ▀█   █▀   ▀█████▀


    v1.2
    @author NFTArca.de
    @title Sacrifice for chapt3r

*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract chapt3rSacrifice {

    struct Witness {
        uint16 id;
        bool chant;
    }

    uint16 minT = 17022;
    uint16 maxT = 17121;

    address public starter = address(0x002287ec2A4232467A06a92457306157a94ad9DC);
    uint256 public bS = 1669788105;

    uint256 public toSacrificeT = 0;
    address public toSacrifice;
    address public prevContract = address(0xF0CDdBa996b43601ddCf1db060B78C0b9249bD5a);

    address[] witnesses;
    uint16[] witnessesT;
    uint16[] witnessesE;

    mapping (address => Witness) witness;

    bool _pause = false;

    bool public godzAppeased = false;

    // Admins
    mapping (address => bool) admins;
    mapping (address => bool) witnessCheck;

    constructor() {
        admins[msg.sender] = true;

        addWitness(address(0x1886988012538fa5b05010f694F4D38DF7939e3C), 17065, 3);
        addWitness(address(0xb8e84Cf45D0E1938718e71De5Ed63eD823F35E5e), 17050, 4);
        addWitness(address(0xE1682954aE4166E784bb3eC9D901E13949A1028e), 17073, 2);
        addWitness(address(0x0b9809573aCA3Ec6F767a3AE622F02ED603b080E), 17067, 1);
        addSacrifice(address(0xBC54F01D118569A1a5F17307D21420653d519A9A), 17072);
    }

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only Minting godz can call this function.");
        _;
    }

    modifier witnessesOnly() {
        require(witnessCheck[msg.sender], "Only witnesses can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(_pause == false, "Someone must begin the sacrifice first.");
        _;
    }

    function addAdmin(address newAdmin) public onlyAdmins{
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) public onlyAdmins{
        admins[oldAdmin] = false;
    }

    function pause() public onlyAdmins {
        _pause = true;
    }

    function unpause() public onlyAdmins {
        _pause = false;
    }

    function uB() public onlyAdmins {
        bS = block.timestamp;
    }

    function addWitness(address newWitnessAddress, uint16 id, uint16 e) public onlyAdmins whenNotPaused {
        require(witnesses.length < 4, "Reached witness limit");
        bool isWitness = false;
        for (uint i=0; i < witnesses.length; i++) {
            if (witnesses[i] == newWitnessAddress){
                isWitness = true;
            }
        }
        require(isWitness == false, "Hero has already proved worthiness");

        require(id >= minT && id <= maxT, "Not a sufficient Witness");

        witnesses.push(newWitnessAddress);
        witnessesT.push(id);
        witnessesE.push(e);
        witnessCheck[newWitnessAddress] = true;

        Witness memory newWitness;
        newWitness.id = id;
        newWitness.chant = false;
        witness[newWitnessAddress] = newWitness;
    }

    function addSacrifice(address sac, uint256 id) public onlyAdmins whenNotPaused {

        require(witnesses.length == 4, "Not enough witnesses have come forward yet");

        require(id >= minT && id <= maxT, "Not a sufficient Sacrifice");

        require(toSacrificeT == 0, "A hero has already offered up sacrifice to the Minting godz");

        bool isWitness = false;
        for (uint i=0; i < witnesses.length; i++) {
            if (witnesses[i] == sac){
                isWitness = true;
            }
        }
        require(isWitness == false, "Hero cannot be a witness and sacrifice");

        toSacrifice = sac;
        toSacrificeT = id;
    }

    function checkWitnessChants() public view whenNotPaused returns (bool[] memory) {

        require(witnesses.length == 4, "Not enough witnesses have come forward to begin voting");

        bool[] memory chants = new bool[](4);
        for (uint i=0; i < witnesses.length; i++) {
            chants[i] = witness[witnesses[i]].chant;
        }

        return chants;
    }

    function chant(bool myChant) public whenNotPaused witnessesOnly {

        require(witnesses.length == 4, "Not enough witnesses have come forward to begin voting");

        require(timeRemaining() > 0, "You have failed to appease the godz. There shall be no reward for the cowardly!");

        require(witness[msg.sender].chant == false, "You have already provided your magic.");

        if (!myChant){
            delete toSacrifice;
            delete toSacrificeT;
            for (uint i=0; i < witnesses.length; i++) {
                witness[witnesses[i]].chant = false;
            }
        }

        witness[msg.sender].chant = myChant;

        uint16 chantCount = 0;
        for (uint i=0; i < witnesses.length; i++) {
            if (witness[witnesses[i]].chant == true){
                chantCount += 1;
            }
        }
        if (chantCount == 4){
            godzAppeased = true;
        }
    }

    function getWitnesses() public view whenNotPaused returns(address[] memory){
        return witnesses;
    }

    function getWitnessesT() public view whenNotPaused returns(uint16[] memory){
        return witnessesT;
    }

    function getWitnessesE() public view whenNotPaused returns(uint16[] memory){
        return witnessesE;
    }

    function startSacrifice() public {
        // Fail to appease the godz in a timely manner and the one who started it will have all their tokens burned
//        require(bS == 0, "The sacrifice has already begun");
//        _pause = false;
//        starter = msg.sender;
//        bS = block.timestamp;
    }

    function timeRemaining() public view returns(uint256) {
        require(bS != 0, "The sacrificial alter has yet to be awaken");
        return (bS + 7 days) - block.timestamp;
    }

    // The sacrificial alter will only make itself visible to those questing for chapt3r on the blue side of the night
}