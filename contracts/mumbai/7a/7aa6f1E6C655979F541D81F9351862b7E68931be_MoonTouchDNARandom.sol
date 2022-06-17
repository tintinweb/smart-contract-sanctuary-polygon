// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./SecurityBase.sol";
import "./IRepeater.sol";

contract MoonTouchDNARandom is SecurityBase {
    event Transfer(string DNA);

    function random(uint256 seed, uint256 x, uint256 step) private view returns (uint256 seedData, uint256 new_seed){
        new_seed = rand(seed);
        seedData = new_seed % x + step;
        // seedData=1;
        // new_seed=1;
    }

    address IRepeaterAddress;
    uint256[] public MoonTouchImageWeight = [5, 5, 10, 10, 10, 10, 10, 10, 15, 15];
    uint256[] public MoonTouchImageReward = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    uint256[] public MoonTouchSpeed = [50, 50, 1, 4, 50, 50, 2, 5, 50, 50, 1, 4, 50, 50, 2, 5, 50, 50, 1, 4, 50, 50, 2, 5, 100, 0, 3, 0, 100, 0, 6, 0];
    uint256[] public MoonTouchAttribute = [480, 48, 144, 240, 24, 72, 120, 12, 36, 60, 6, 18, 40, 4, 12];
    uint256[] public MoonTouchAttributeWeight01 = [0, 0, 3333, 3333, 3334];
    uint256[] public MoonTouchAttributeWeight02 = [55, 27, 5, 5, 556];
    uint256[] public MoonTouchAttributeWeight03 = [714, 714, 714, 714, 7144];
    uint256[] public MoonTouchAttributeWeight04 = [2000, 2000, 2000, 2000, 2000];
    uint256[] public MoonTouchDurability = [2, 4, 3, 6, 4, 7, 2, 6, 3, 7, 2, 7];


    bytes32[] private images = new bytes32[](10);
    bytes32[] private speeds = new bytes32[](10);

    bool preMintFlag = true;

    constructor() {

        speeds[0] = keccak256(abi.encode("01"));
        speeds[1] = keccak256(abi.encode("02"));
        speeds[2] = keccak256(abi.encode("03"));
        speeds[3] = keccak256(abi.encode("04"));
        speeds[4] = keccak256(abi.encode("05"));
        speeds[5] = keccak256(abi.encode("06"));

        images[0] = keccak256(abi.encode("001"));
        images[1] = keccak256(abi.encode("002"));
        images[2] = keccak256(abi.encode("003"));
        images[3] = keccak256(abi.encode("004"));
        images[4] = keccak256(abi.encode("005"));
        images[5] = keccak256(abi.encode("006"));
        images[6] = keccak256(abi.encode("007"));
        images[7] = keccak256(abi.encode("008"));
        images[8] = keccak256(abi.encode("009"));
        images[9] = keccak256(abi.encode("010"));
    }

    function setIRepeater(address repeater) public onlyMinter {
        IRepeaterAddress = repeater;
    }

    function rand(uint256 _seed) public view returns (uint256){
        return uint256(keccak256(abi.encodePacked(_seed, block.number, block.timestamp, block.coinbase)));
    }

    function get11MoonTouchDNA() public onlyMinter returns (string memory DNA){
        uint256 seed = getDraw(500);
        string memory image;
        (image, seed) = getImage(seed);
        string memory grade = "00";
        string memory camp = getCamp(keccak256(abi.encode(image)));
        string memory character = getCharacter(keccak256(abi.encode(image)));
        string memory speed;
        (speed, seed) = getSpeed(seed, keccak256(abi.encode(image)));
        string memory generation = "01";
        string memory attribute;
        (attribute, seed) = getAttribute(seed, keccak256(abi.encode(character)), keccak256(abi.encode(camp)));
        string memory durabilityDate;
        (durabilityDate, seed) = getDurability(seed, keccak256(abi.encode(speed)));
        durabilityDate = _stringJoin(durabilityDate, durabilityDate);
        string memory temper = "3";
        string memory reproduction = "77";
        string memory evolutionary = "99";
        string memory gene1 = _stringJoin("#", character);
        string memory gene2 = _stringJoin("&", character);
        DNA = _stringJoin("A01", image);
        DNA = _stringJoin(DNA, grade);
        DNA = _stringJoin(DNA, camp);
        DNA = _stringJoin(DNA, character);
        DNA = _stringJoin(DNA, speed);
        DNA = _stringJoin(DNA, generation);
        DNA = _stringJoin(DNA, attribute);
        DNA = _stringJoin(DNA, durabilityDate);
        DNA = _stringJoin(DNA, temper);
        DNA = _stringJoin(DNA, reproduction);
        DNA = _stringJoin(DNA, evolutionary);
        DNA = _stringJoin(DNA, gene1);
        DNA = _stringJoin(DNA, gene2);
        emit Transfer(DNA);
    }

    function getImage(uint256 seed) public view onlyMinter returns (string memory winData, uint256 seedDate){
        uint256 gross = 0;
        for (uint256 i = 0; i < MoonTouchImageWeight.length; i++) {
            gross = gross + MoonTouchImageWeight[i];
        }
        uint256 win;

        (win, seedDate) = weightNmb(seed, MoonTouchImageWeight, gross);
        winData = getSoleAttributeDate(MoonTouchImageReward[win], 3);
    }

    function getDurability2(uint256 seed, string memory speed) public view onlyMinter returns (string memory winDate, uint256 seedDate){
        uint256[] memory weight = new uint256[](2);
        uint256[] memory reward = new uint256[](2);
        weight[0] = 50;
        weight[1] = 50;
        uint256 gross = 100;
        if (keccak256(abi.encode(speed)) == speeds[0]) {
            reward[0] = MoonTouchDurability[0];
            reward[1] = MoonTouchDurability[1];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (keccak256(abi.encode(speed)) == speeds[1]) {
            reward[0] = MoonTouchDurability[2];
            reward[1] = MoonTouchDurability[3];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (keccak256(abi.encode(speed)) == speeds[2]) {
            reward[0] = MoonTouchDurability[4];
            reward[1] = MoonTouchDurability[5];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (keccak256(abi.encode(speed)) == speeds[3]) {
            reward[0] = MoonTouchDurability[6];
            reward[1] = MoonTouchDurability[7];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (keccak256(abi.encode(speed)) == speeds[4]) {
            reward[0] = MoonTouchDurability[8];
            reward[1] = MoonTouchDurability[9];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (keccak256(abi.encode(speed)) == speeds[5]) {
            reward[0] = MoonTouchDurability[10];
            reward[1] = MoonTouchDurability[11];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        return ("000", seed);
    }

    function getDurability(uint256 seed, bytes32 speed) public view onlyMinter returns (string memory winDate, uint256 seedDate){
        uint256[] memory weight = new uint256[](2);
        uint256[] memory reward = new uint256[](2);
        weight[0] = 50;
        weight[1] = 50;
        uint256 gross = 100;
        if (speed == speeds[0]) {
            reward[0] = MoonTouchDurability[0];
            reward[1] = MoonTouchDurability[1];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (speed == speeds[1]) {
            reward[0] = MoonTouchDurability[2];
            reward[1] = MoonTouchDurability[3];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (speed == speeds[2]) {
            reward[0] = MoonTouchDurability[4];
            reward[1] = MoonTouchDurability[5];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (speed == speeds[3]) {
            reward[0] = MoonTouchDurability[6];
            reward[1] = MoonTouchDurability[7];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (speed == speeds[4]) {
            reward[0] = MoonTouchDurability[8];
            reward[1] = MoonTouchDurability[9];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        if (speed == speeds[5]) {
            reward[0] = MoonTouchDurability[10];
            reward[1] = MoonTouchDurability[11];
            uint256 win;
            (win, seedDate) = weightNmb(seed, weight, gross);
            winDate = getSoleAttributeDate(reward[win], 3);
            return (winDate, seedDate);
        }
        return ("000", seed);
    }


    function getAttribute(uint256 seed, bytes32 character, bytes32 camp) public view onlyMinter returns (string memory, uint256 seedDate){
        RandomCtx memory ctx;

        if (camp == speeds[0]) {
            ctx.WeightAndRewardData = MoonTouchAttributeWeight01;
        }
        if (camp == speeds[1]) {
            ctx.WeightAndRewardData = MoonTouchAttributeWeight02;
        }
        if (camp == speeds[2]) {
            ctx.WeightAndRewardData = MoonTouchAttributeWeight03;
        }
        if (camp == speeds[3]) {
            ctx.WeightAndRewardData = MoonTouchAttributeWeight04;
        }
        if (character == speeds[0]) {
            ctx.seed = seed;
            ctx.allMax = MoonTouchAttribute[0];
            ctx.least = MoonTouchAttribute[1];
            ctx.soleMax = MoonTouchAttribute[2];
            return getAttributeRandom(ctx);
        }
        if (character == speeds[1]) {
            ctx.seed = seed;
            ctx.allMax = MoonTouchAttribute[3];
            ctx.least = MoonTouchAttribute[4];
            ctx.soleMax = MoonTouchAttribute[5];
            return getAttributeRandom(ctx);
        }
        if (character == speeds[2]) {
            ctx.seed = seed;
            ctx.allMax = MoonTouchAttribute[6];
            ctx.least = MoonTouchAttribute[7];
            ctx.soleMax = MoonTouchAttribute[8];
            return getAttributeRandom(ctx);
        }
        if (character == speeds[3]) {
            ctx.seed = seed;
            ctx.allMax = MoonTouchAttribute[9];
            ctx.least = MoonTouchAttribute[10];
            ctx.soleMax = MoonTouchAttribute[11];
            return getAttributeRandom(ctx);
        }
        if (character == speeds[4]) {
            ctx.seed = seed;
            ctx.allMax = MoonTouchAttribute[12];
            ctx.least = MoonTouchAttribute[13];
            ctx.soleMax = MoonTouchAttribute[14];
            return getAttributeRandom(ctx);
        }
        return ("100000000000001", seed);
    }

    struct RandomCtx {
        uint256 seed;
        uint256 allMax;
        uint256 least;
        uint256 soleMax;
        uint256[] WeightAndRewardData;
    }

    function getAttributeRandom(RandomCtx memory ctx) public view onlyMinter returns (string memory date, uint256 seedDate){
        uint256 gross = 0;
        for (uint256 i = 0; i < ctx.WeightAndRewardData.length; i++) {
            gross = gross + ctx.WeightAndRewardData[i];
        }
        uint256 stat = ctx.allMax - ctx.least * 5;
        uint256 residueStat = stat;

        uint256 power = 0;
        (power, ctx.seed) = getRandomAttributeNumber(ctx, gross, stat, 0, residueStat);
        residueStat = residueStat - power;
        power = power + ctx.least;

        uint256 boost = 0;
        (boost, ctx.seed) = getRandomAttributeNumber(ctx, gross, stat, 1, residueStat);
        residueStat = residueStat - boost;
        boost = boost + ctx.least;

        uint256 tenacity = 0;
        (tenacity, ctx.seed) = getRandomAttributeNumber(ctx, gross, stat, 2, residueStat);
        residueStat = residueStat - tenacity;
        tenacity = tenacity + ctx.least;


        uint256 spirit = 0;
        (spirit, ctx.seed) = getRandomAttributeNumber(ctx, gross, stat, 3, residueStat);
        residueStat = residueStat - spirit;
        spirit = spirit + ctx.least;

        uint256 lucky = 0;
        (lucky, ctx.seed) = getRandomAttributeNumber(ctx, gross, stat, 4, residueStat);
        residueStat = residueStat - lucky;
        lucky = lucky + ctx.least;

        date = _stringJoin(getSoleAttributeDate(power, 3), getSoleAttributeDate(boost, 3));
        date = _stringJoin(date, getSoleAttributeDate(tenacity, 3));
        date = _stringJoin(date, getSoleAttributeDate(spirit, 3));
        date = _stringJoin(date, getSoleAttributeDate(lucky, 3));
        seedDate = ctx.seed;
    }

    function getRandomAttributeNumber(RandomCtx memory ctx, uint256 gross, uint256 stat, uint256 AttributeType, uint256 residueStat) public view returns (uint256 rt, uint256 seedData){
        uint256 percentage;
        uint256 attributeNumer = 0;
        uint256 availableTime = ctx.soleMax - ctx.least;
        if (ctx.WeightAndRewardData[AttributeType] == 0) {
            return (ctx.least, ctx.seed);
        }
        if (ctx.WeightAndRewardData[AttributeType] != 0) {
            percentage = gross / ctx.WeightAndRewardData[AttributeType];
            attributeNumer = stat / percentage;
            if (attributeNumer > availableTime) {
                attributeNumer = availableTime;
            }
            return getAttributeNumber(ctx.seed, attributeNumer, AttributeType, residueStat);
        }
    }


    function getAttributeNumber(uint256 ctxSeed, uint256 attributeNumer, uint256 AttributeType, uint256 residueStat) public view onlyMinter returns (uint256 rewardDate, uint256 seedData){
        uint256 attributeMaxNumer = attributeNumer * 12 / 10;
        uint256 attributeMinNumer = attributeNumer * 8 / 10;
        if (attributeMaxNumer > residueStat) {
            attributeMaxNumer = residueStat;
            attributeMinNumer = attributeMaxNumer * 8 / 10;
        }
        uint256 time = attributeMaxNumer - attributeMinNumer + 1;
        uint256[] memory randomNumber = new uint256[](time);
        uint256[] memory weightNumber = new uint256[](time);
        uint256 allGross = 0;
        for (uint256 i = 0; i < time; i++) {
            randomNumber[i] = attributeMinNumer + i;
            weightNumber[i] = 50;
            allGross = allGross + 50;
        }
        uint256 win;
        (win, ctxSeed) = weightNmb(ctxSeed, weightNumber, allGross);
        rewardDate = randomNumber[win];
        if (AttributeType == 4) {
            if (residueStat > rewardDate) {
                return (rewardDate, ctxSeed);
            }
        }
        return (rewardDate, ctxSeed);
    }

    function speedRandom(uint256 seed, uint256 weight1, uint256 weight2, uint256 reward1, uint256 reward2) public view onlyMinter returns (string memory rewardDate, uint256 seedData){
        uint256[] memory weight = new uint256[](2);
        uint256[] memory reward = new uint256[](2);
        reward[0] = reward1;
        reward[1] = reward2;
        weight[0] = weight1;
        weight[1] = weight2;

        uint256 gross = 0;
        for (uint256 i = 0; i < weight.length; i++) {
            gross = gross + weight[i];
        }
        uint256 win;
        (win, seedData) = weightNmb(seed, weight, gross);
        rewardDate = getSoleAttributeDate(reward[win], 2);
    }

    function getSpeed(uint256 seed, bytes32 image) internal view onlyMinter returns (string memory, uint256 seedDate){
        if (image == images[0]) {
            return speedRandom(seed, MoonTouchSpeed[0], MoonTouchSpeed[1], MoonTouchSpeed[2], MoonTouchSpeed[3]);
        }
        if (image == images[1]) {
            return speedRandom(seed, MoonTouchSpeed[4], MoonTouchSpeed[5], MoonTouchSpeed[6], MoonTouchSpeed[7]);
        }
        if (image == images[2]) {
            return speedRandom(seed, MoonTouchSpeed[8], MoonTouchSpeed[9], MoonTouchSpeed[10], MoonTouchSpeed[11]);
        }
        if (image == images[3]) {
            return speedRandom(seed, MoonTouchSpeed[12], MoonTouchSpeed[13], MoonTouchSpeed[14], MoonTouchSpeed[15]);
        }
        if (image == images[4]) {
            return speedRandom(seed, MoonTouchSpeed[16], MoonTouchSpeed[17], MoonTouchSpeed[18], MoonTouchSpeed[19]);
        }
        if (image == images[5]) {
            return speedRandom(seed, MoonTouchSpeed[20], MoonTouchSpeed[21], MoonTouchSpeed[22], MoonTouchSpeed[23]);
        }
        if (image == images[6]) {
            return speedRandom(seed, MoonTouchSpeed[24], MoonTouchSpeed[25], MoonTouchSpeed[26], MoonTouchSpeed[27]);
        }
        if (image == images[7]) {
            return speedRandom(seed, MoonTouchSpeed[24], MoonTouchSpeed[25], MoonTouchSpeed[26], MoonTouchSpeed[27]);
        }
        if (image == images[8]) {
            return speedRandom(seed, MoonTouchSpeed[28], MoonTouchSpeed[29], MoonTouchSpeed[30], MoonTouchSpeed[31]);
        }
        if (image == images[9]) {
            return speedRandom(seed, MoonTouchSpeed[28], MoonTouchSpeed[29], MoonTouchSpeed[30], MoonTouchSpeed[31]);
        }
        return ("00", 500);
    }

    function getCharacter(bytes32 image) internal view onlyMinter returns (string memory){
        string memory data1 = "01";
        string memory data2 = "02";
        string memory data3 = "03";
        string memory data4 = "04";
        string memory data5 = "05";
        if (image == images[0]) {
            return data1;
        }
        if (image == images[1]) {
            return data2;
        }
        if (image == images[2]) {
            return data3;
        }
        if (image == images[3]) {
            return data4;
        }
        if (image == images[4]) {
            return data5;
        }
        if (image == images[5]) {
            return data5;
        }
        if (image == images[6]) {
            return data5;
        }
        if (image == images[7]) {
            return data5;
        }
        if (image == images[8]) {
            return data5;
        }
        if (image == images[9]) {
            return data5;
        }
        return "00";
    }

    function getCamp(bytes32 image) public view onlyMinter returns (string memory){
        string memory data1 = "01";
        string memory data2 = "02";
        string memory data3 = "03";
        string memory data4 = "04";
        if (image == images[0]) {
            return data1;
        }
        if (image == images[1]) {
            return data2;
        }
        if (image == images[2]) {
            return data1;
        }
        if (image == images[3]) {
            return data2;
        }
        if (image == images[4]) {
            return data1;
        }
        if (image == images[5]) {
            return data2;
        }
        if (image == images[6]) {
            return data3;
        }
        if (image == images[7]) {
            return data3;
        }
        if (image == images[8]) {
            return data4;
        }
        if (image == images[9]) {
            return data4;
        }
        return "00";
    }


    function getDraw(uint256 gross) public onlyMinter returns (uint256 win){
        win = IRepeater(IRepeaterAddress).get_random_int(gross, 0, msg.sender);
    }

    function weightNmb(uint256 seed, uint256[] memory weight, uint256 gross) public view onlyMinter returns (uint256 win, uint256 seedData){
        uint256 newData = 0;
        uint256 draw;
        (draw, seedData) = random(seed, gross, 0);
        for (uint256 n = 0; n < weight.length; n++) {
            newData = newData + weight[n];
            if (draw < newData) {
                win = n;
                return (win, seedData);
            }
        }
        return (win, seedData);
    }


    function setMoonTouchImageWeight(uint256[] memory moonTouchImageWeight) external onlyMinter {
        MoonTouchImageWeight = moonTouchImageWeight;
    }

    function getMoonTouchImageWeightAll() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchImageWeight;
    }

    function setMoonTouchImageReward(uint256[] memory moonTouchImageReward) external onlyMinter {
        MoonTouchImageReward = moonTouchImageReward;
    }

    function getMoonTouchImageRewardAll() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchImageWeight;
    }

    function setMoonTouchSpeed(uint256[] memory moonTouchSpeed) external onlyMinter {
        MoonTouchSpeed = moonTouchSpeed;
    }

    function getMoonTouchSpeedAll() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchSpeed;
    }

    function setMoonTouchAttribute(uint256[] memory moonTouchAttribute) external onlyMinter {
        MoonTouchAttribute = moonTouchAttribute;
    }

    function getMoonTouchAttributeAll() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchAttribute;
    }


    function setMoonTouchAttributeWeight01(uint256[] memory moonTouchAttributeWeight01) external onlyMinter {
        MoonTouchAttributeWeight01 = moonTouchAttributeWeight01;
    }

    function getMoonTouchAttributeWeight01All() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchAttributeWeight01;
    }

    function setMoonTouchAttributeWeight02(uint256[] memory moonTouchAttributeWeight02) external onlyMinter {
        MoonTouchAttributeWeight02 = moonTouchAttributeWeight02;
    }

    function getMoonTouchAttributeWeight02All() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchAttributeWeight02;
    }

    function setMoonTouchAttributeWeight03(uint256[] memory moonTouchAttributeWeight03) external onlyMinter {
        MoonTouchAttributeWeight03 = moonTouchAttributeWeight03;
    }

    function getMoonTouchAttributeWeight03All() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchAttributeWeight03;
    }

    function setMoonTouchAttributeWeight04(uint256[] memory moonTouchAttributeWeight04) external onlyMinter {
        MoonTouchAttributeWeight04 = moonTouchAttributeWeight04;
    }

    function getMoonTouchAttributeWeight04All() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchAttributeWeight04;
    }


    function setMoonTouchDurability(uint256[] memory moonTouchDurability) external onlyMinter {
        MoonTouchDurability = moonTouchDurability;
    }

    function getMoonTouchDurabilityAll() public virtual onlyMinter returns (uint256[] memory) {
        return MoonTouchDurability;
    }

    function getSoleAttributeDate(uint256 date, uint256 number) public pure returns (string memory _uintAsString){
        string memory intactData = _uint2str(date);
        uint256 shortNumber = number - bytes(intactData).length;
        string memory shortDate = "";
        string memory placeholder = "0";
        for (uint256 i = 0; i < shortNumber; i++) {
            shortDate = _stringJoin(shortDate, placeholder);
        }
        return _stringJoin(shortDate, intactData);
    }

    function _stringJoin(string memory _a, string memory _b) private pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function _uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecurityBase is AccessControlEnumerable, Pausable {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _;
    }

    constructor() {
        _init_admin_role();
    }

    // init creator as admin role
    function _init_admin_role() internal virtual {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function grantMinter(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)) {
        _setupRole(MINTER_ROLE, account);
    }

    function grantPauser(address account) public virtual onlyRole(getRoleAdmin(PAUSER_ROLE)) {
        _setupRole(PAUSER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRepeater {
     function get_random_int(uint x, uint step, address user)external  returns (uint new_seed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
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
interface IERC165 {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}