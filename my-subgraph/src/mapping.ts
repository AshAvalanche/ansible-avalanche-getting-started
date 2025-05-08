import {
    Transfer as TransferEvent,
    Approval as ApprovalEvent
  } from "../generated/ASHToken/ASHToken"
  import { Transfer, Approval } from "../generated/schema"

  export function handleTransfer(event: TransferEvent): void {
    let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHex()
    let entity = new Transfer(id)
    entity.from = event.params.from
    entity.to = event.params.to
    entity.value = event.params.value
    entity.blockNumber = event.block.number
    entity.timestamp = event.block.timestamp
    entity.save()
  }

  export function handleApproval(event: ApprovalEvent): void {
    let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHex()
    let entity = new Approval(id)
    entity.owner = event.params.owner
    entity.spender = event.params.spender
    entity.value = event.params.value
    entity.blockNumber = event.block.number
    entity.timestamp = event.block.timestamp
    entity.save()
  }
