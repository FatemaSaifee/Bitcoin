defmodule BitcoinTest do
  use ExUnit.Case
  doctest Bitcoin

  test "bitcoin" do
  	IO.puts ""
    IO.puts "Bitcoin testing started"	
    IO.puts ""
    networkId = Network.generateNetwork()
    
		transactionId = Transaction.genesisTransaction()
		genesisBlockId = Block.genesisBlock(transactionId)
		blockchain = [genesisBlockId]
		Network.updateNetworkBlockchain(networkId, blockchain)
		


    numWallets = 2
		walletPublicKeyList = Enum.map(1..numWallets, fn(x) -> 
			Wallet.generateWallet(x, blockchain, networkId)
		end)

		[sender,receiver] = Enum.map(0..numWallets-1, fn(x) -> 
			Enum.fetch!(Enum.fetch!(walletPublicKeyList, x), 0)
		end)


    Bitcoin.mining(sender)
    Bitcoin.mining(receiver)
    :timer.sleep(3000)

    amount = 10
    {_, _, _, _, _, _, _, _, _, senderBalanceBefore} = Wallet.getWalletState(sender)
    {_, _, _, _, _, _, _, _, _, receiverBalanceBefore} = Wallet.getWalletState(receiver)

    IO.puts "Checking balance of wallet 1 after mining is greater than 0"
    assert senderBalanceBefore > 0
    IO.puts "true"
    IO.puts "Checking balance of wallet 2 after mining is greater than 0"
    assert receiverBalanceBefore > 0
    IO.puts "true"
    
    IO.puts "Creating wallet to wallet transaction"
    Transaction.createWalletToWalletTx(sender,receiver,amount) 

      
    {_, _, _, _, _, _, _, _, _, senderBalanceAfter} = Wallet.getWalletState(sender)
    {_, _, _, _, _, _, _, _, _, receiverBalanceAfter} = Wallet.getWalletState(receiver)

    IO.puts "senderBalanceBefore - amount = senderBalanceAfter?"
    assert senderBalanceBefore - amount == senderBalanceAfter
    IO.puts "true"
    IO.puts("receiverBalanceBefore + amount = receiverBalanceAfter?")
    assert receiverBalanceBefore + amount == receiverBalanceAfter
    IO.puts "true"
  end
end
