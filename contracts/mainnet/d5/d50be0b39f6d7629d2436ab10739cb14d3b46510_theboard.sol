/**
 *Submitted for verification at polygonscan.com on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract theboard { 
    event PixelTransfer(uint position, address newOwner, address formerOwner, uint price, uint newPrice, string newColorUrl); 
    struct Pixel { 
        string colorurl; 
        address owner;
        uint price;
    } 

    uint initPrice; 
    uint incrIndex;
    uint masterFee;
    address payable private master; 
    mapping (uint => mapping (uint => Pixel)) public pixels; // x => y => Pixel

    constructor () { 
        master = payable(msg.sender);
        initPrice  = 100000000000000000; 
        incrIndex  = 125;
        masterFee  = 1;
    } 

    function purchasePixel(uint _x, uint _y, string memory _colorurl) private {  
        Pixel memory pix    = pixels[_x][_y];
        require((_x < 766) && (_x > 0) && (_y < 351) && (_y > 0), "coords out of range");
        address payable _formerOwner;
        uint _oldPrice      = pix.price; 
        uint _newPrice;
        if (_oldPrice > 0) { // pixel exists
            _formerOwner    = payable(pix.owner);  
        }
        else {
            _oldPrice       = initPrice;
            _formerOwner    = payable(master);
        } 
        _newPrice           = _oldPrice * incrIndex / 100;
        pixels[_x][_y]      = Pixel(_colorurl, msg.sender, _newPrice);
        _formerOwner.transfer(_oldPrice); 
        emit PixelTransfer(uint(_x) * 10000 + uint(_y), msg.sender, _formerOwner, _oldPrice, _newPrice, _colorurl); 
    }

    function getPayment(uint[] memory _xpos, uint[] memory _ypos) public view returns(uint _payment) {
        uint posSize = _xpos.length; 
        uint _price;
        for (uint i=0; i < posSize; i++) { 
            _price = pixels[_xpos[i]][_ypos[i]].price;
            if (_price > 0) { _payment += _price; }
            else { _payment += initPrice; } 
        }
        return _payment;
    }

    function purchasePixels(uint[] memory _xpos, uint[] memory _ypos, string[] memory _colorurl, uint _maxPayment) public payable {
        uint _len = _xpos.length;
        require((_len == _ypos.length) && (_len == _colorurl.length), "length isn't equal");
        uint _payment    = getPayment(_xpos, _ypos);
        uint _fee        = _payment / 100 * masterFee;
        if (_maxPayment == 0)   { require(msg.value >= (_payment + _fee), "not enough payment"); }
        else                    { require(_maxPayment >= (_payment + _fee), "not enough payment"); }
        for (uint i = 0; i < _len; i++ ) { purchasePixel(_xpos[i], _ypos[i], _colorurl[i]); }

        master.transfer(_fee);

        if ((msg.value - _fee - _payment) > 0) { payable(msg.sender).transfer(msg.value - _fee - _payment); }
    } 

    function getPix(uint _x, uint _y) public view returns(Pixel memory) {
        return Pixel(pixels[_x][_y].colorurl, pixels[_x][_y].owner, pixels[_x][_y].price);
    } 
}