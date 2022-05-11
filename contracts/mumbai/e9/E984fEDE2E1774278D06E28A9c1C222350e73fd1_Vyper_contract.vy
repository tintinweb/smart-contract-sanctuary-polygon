# @version ^0.2
from vyper.interfaces import ERC20  
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256  
interface UniswapV2Router:
  def swapExactTokensForTokens(
    amountIn: uint256,
    amountOutMin: uint256,
    path: address[3],
    to: address,
    deadline: uint256
  ) -> uint256[3]: nonpayable
USDT:constant(address) = 0xB0Dfaaa92e4F3667758F2A864D50F94E8aC7a56B
UNISWAP: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
WETH: constant(address) = 0xc778417E063141139Fce010982780140Aa0cD5Ab
DAI: constant(address) =  0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
USER: constant(address) = 0xde04ec74143f471fE505d107E5E784b1E4eec390
LINK: constant(address) = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB

owner: public(address)
charity: public(address)
seller : public(address)
startup : public(address)
bot: public(address)
broker: public(address)

@external
def __init__(_charity: address, _seller: address,_startup: address,_broker: address,_bot: address):
	self.broker = _broker
	self.charity = _charity
	self.seller = _seller
	self.startup = _startup
	self.bot = _bot
	self.owner = msg.sender
	
@internal
def distributer():
	curamount:uint256 = ERC20(DAI).balanceOf(self)
	ERC20(DAI).approve(self, curamount)
	sendamount:uint256 = curamount*40/100
	ERC20(DAI).transferFrom(self, self.broker, sendamount)
	log Transfer(self, self.broker, sendamount)
	ERC20(DAI).transferFrom(self, self.bot, 1)
	log Transfer(self, self.bot, 1)
	curamount = curamount-sendamount - 1
	sendamount = curamount*30/100
	ERC20(DAI).transferFrom(self, self.charity, sendamount)
	log Transfer(self, self.charity, sendamount)
	ERC20(DAI).transferFrom(self, self.seller, sendamount)
	log Transfer(self, self.seller, sendamount)
	ERC20(DAI).transferFrom(self, self.startup, sendamount)
	log Transfer(self, self.startup, sendamount)
@external
def swap(amountIn: uint256):
   ERC20(LINK).transferFrom(msg.sender,self, amountIn)
  # ERC20(LINK).approve(UNISWAP, amountIn*10)
  # res: Bytes[128] = raw_call(
  #  UNISWAP,
  #  concat(
  #    method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"),
  #    convert(amountIn, bytes32),        # amount in
  #    convert(0, bytes32),               # amount out min
  #    convert(160, bytes32),             # path[] offset (5 * 32, 5 = number of func args)
  #    convert(self, bytes32),            # to
   #   convert(block.timestamp, bytes32), # deadline
   #   convert(3, bytes32),               # path[] length
   #   convert(LINK, bytes32),
	#  convert(WETH, bytes32),
   #   convert(DAI, bytes32)
   # ),
  #  max_outsize=128,
  #)
  #self.distributer()