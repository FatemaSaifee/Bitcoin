import Commons
import Network
import GenerateRandomString
import Wallet
import Block
import Transaction
import Network

defmodule Bitcoin do
	@moduledoc """
	Documentation for Bitcoin.
	"""

	@doc """
	Main
	"""
	def main do
		IO.puts ""
		IO.puts ""
		IO.puts ""
		networkId = generateNetwork()
		IO.puts "Network created..."

		transactionId = genesisTransaction()
		# IO.puts transactionId
		IO.puts "Genesis transaction created..."


		# Initialize a ets table to store a global count for each Node
		# table = :ets.new(:table, [:named_table,:public])
		# :ets.insert(table, {"globalNodeCount",0})


		# blockId=startBlock()
		genesisBlockId = genesisBlock(transactionId)
		IO.puts "Genesis block created..."
		blockchain = [genesisBlockId]
		IO.puts "Blockchain created with Genesis block..."
		updateNetworkBlockchain(networkId, blockchain)
		

		# Create wallets
		numWallets = 10
		walletPublicKeyList = Enum.map(1..numWallets, fn(x) -> 
			generateWallet(x, blockchain, networkId)
		end)

		allWalletIds = Enum.map(0..numWallets-1, fn(x) -> 
			Enum.fetch!(Enum.fetch!(walletPublicKeyList, x), 0)
		end)

		allPublicKeys = Enum.map(0..numWallets-1, fn(x) -> 
			Enum.fetch!(Enum.fetch!(walletPublicKeyList, x), 1)
		end)

		updateNetworkWalletIdMaps(networkId,walletPublicKeyList)

		

		Enum.each(0..numWallets-1, fn(x) -> 
			wId =  Enum.fetch!(Enum.fetch!(walletPublicKeyList, x), 0)
			updateWalletPublicKeys(wId, allPublicKeys)
			# IO.inspect :calendar.local_time()
			Task.start(Bitcoin,:mining,[wId])
		end)


		:timer.sleep(10000)	
		Enum.each(1..10,fn(x)-> 
			[sender,receiver] = Enum.take_random(allWalletIds,2)
			amountToSend = 7.5
			IO.puts "Transaction #{x} :"
			createWalletToWalletTx(sender,receiver,amountToSend)
			IO.puts "All wallet balances after transaction #{x}"
			IO.puts("-----------------------------")
			IO.puts("| WALLET ID     |  BALANCE  |")
			Enum.each(allWalletIds, fn(y)->
				getWalletBalance(y)
			end)
			IO.puts("-----------------------------")
			# getWalletBalance(Enum.fetchallWalletIds)
			# getWalletBalance(receiver)
		end)
		
		# waitIndefinitely()

	end

	################################################
	# Basic blockchain functions
	################################################





	def isBlockValid(newBlockId, oldBlockId) do
		{oldBlockIndex, oldBlockTime, oldBlockHash, oldBlockPrevHash, oldBlocktransactions, oldBlockLength, oldBlockMerkleRoot} = getBlockState(oldBlockId)
		{newBlockIndex, newBlockTime,  newBlockHash, newBlockPrevHash, newBlocktransactions, newBlockLength, newBlockMerkleRoot} = getBlockState(newBlockId)
		true
		if oldBlockIndex+1 != newBlockIndex do
			IO.puts "index"
		        false
		else
				if oldBlockHash != newBlockPrevHash do
					IO.puts "prevHash"
		        	false
				else
					if calculateHash(newBlockId) != newBlockHash do
						IO.puts "newHash"
		   		     	false
					else
						true
					end		
				end
		end
		
	end

	def replaceChain(newBlocks) do
		# if len(newBlocks) > len(Blockchain) do
		#   Blockchain = newBlocks
		# end
	end

	################################################
	# Mining
	################################################
	def mining(walletId) do
		{name, publicKey, privateKey, allPublicKeys, uTransactions, allTransactions, blockchain, target, networkId, walletBalance} = getWalletState(walletId)
		
		networkBlockchain = getNetworkBlockchain(networkId)
		lastBlockId = Enum.fetch!(blockchain, length(blockchain)-1)
		blockchain = updateWalletBlockchain(walletId, networkBlockchain)

		
		{blockIndex, blockTime, blockHash, blockPrevHash, blockTransactions, blockLength, blockMerkleRoot} = getBlockState(lastBlockId)

		# get random string with length <difficulty>
		nonce = randomizer(10)
		newValueHash = blockHash <> nonce
		newHash = generateHash(newValueHash)
		if (String.slice(newHash, 0..target) == String.duplicate("0", target+1)) do
			#  create a new block
			# IO.inspect :calendar.local_time()
			# IO.puts nonce
			# create acoinbase transaction
			# inputHash, inputSignature, inputPublicKey
			coinBaseTransactionInputs = [
				[
					String.duplicate("0", 64),
					"",
					generateHash("")
				]
			]
			blockReward = 12.5
			coinBaseTransactionOutputs = [
				[
					blockReward,
					publicKey
				]
			]
			coinBaseTransactionId = generateTransaction(coinBaseTransactionInputs, coinBaseTransactionOutputs)
			

			
			transactions = getNetworkTransactionPool(networkId)
			# IO.inspect transactions

			blockId = generateBlock(lastBlockId, [coinBaseTransactionId]  ++ transactions)
			# Add block to the blockchain
			newBlockChain = blockchain ++ [blockId]
			removeTransactionFromPool(networkId, transactions)

			# IO.inspect isBlockValid(blockId,lastBlockId)

			if isBlockValid(blockId,lastBlockId) do

				IO.puts "Nonce: #{nonce}"
				updateNetworkBlockchain(networkId,newBlockChain)
				updateWalletBlockchain(walletId, newBlockChain)

				# create a new transaction for bitcoin reward
				# add it to transaction pool

				# System.halt(0);
				# isBlockValid(blockId)




				updateWalletUnusedTransactions(walletId, coinBaseTransactionId,blockReward)
				{name, publicKey, privateKey, allPublicKeys, uTransactions, allTransactions, blockchain, target, networkId, walletBalance} = getWalletState(walletId)
				
				IO.puts "Bitcoin mined successfully!"
				# IO.inspect {name, publicKey, privateKey, allPublicKeys, uTransactions, allTransactions, blockchain, target, networkId, walletBalance}

				getWalletBalance(walletId)
			else
				mining(walletId)
			end
			
		else
			mining(walletId)
		end


	end

	# def mining(name, publicKey, privateKey, allPublicKeys, uTransactions, allTransactions, blockchain, target, blockIndex, blockTime, blockHash, blockPrevHash, blockTransactions, blockLength, blockMerkleRoot)


end

Bitcoin.main()
