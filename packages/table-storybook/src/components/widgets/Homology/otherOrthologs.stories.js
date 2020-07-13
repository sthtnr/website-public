import React from 'react'
import Orthologs from './Orthologs'
import { homology_widget } from '../../../../.storybook/target'

export default {
  component: Orthologs,
  title: 'Table|Widgets/Homology/other_orthologs',
}

export const daf8 = () => (
  <Orthologs
    WBid={homology_widget.WBid.daf8}
    tableType={homology_widget.tableType.otherOrthologs}
  />
)
export const daf16 = () => (
  <Orthologs
    WBid={homology_widget.WBid.daf16}
    tableType={homology_widget.tableType.otherOrthologs}
  />
)
export const mig2 = () => (
  <Orthologs
    WBid={homology_widget.WBid.mig2}
    tableType={homology_widget.tableType.otherOrthologs}
  />
)