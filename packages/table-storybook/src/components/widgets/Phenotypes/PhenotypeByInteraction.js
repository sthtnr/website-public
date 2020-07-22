import React, { useMemo, useState, useEffect} from 'react'
import Table from './Table'
import loadData from '../../../services/loadData'

const PhenotypeByInteraction = ({ data }) => {
  const [datax, setDatax] = useState([])
  useEffect(() => {
    loadData('WBGene00000912', 'phenotype_by_interaction').then((json) => setDatax(json.data))
  }, [])

  const showInteractions = (value) => {
    return value.map((detail, idx) => (
      <ul key={idx}>
        <li>{detail.label}</li>
      </ul>
    ))
  }

  const showCitations = (value) => {
    return value.map((detail, idx) => (
      <ul key={idx}>
        <li>{detail[0]?.label ? detail[0].label : null}</li>
      </ul>
    ))
  }

  const columns = useMemo(
    () => [
      {
        Header: 'Phenotype',
        accessor: 'phenotype.label',
      },
      {
        Header: 'Interactions',
        accessor: 'interactions',
        Cell: ({ cell: { value } }) => showInteractions(value),
        sortType: 'sortByInteractions',
        disableFilters: true,
        width: 200,
        minWidth: 145,
      },
      {
        Header: 'Interaction Type',
        accessor: 'interaction_type',
      },
      {
        Header: 'Citations',
        accessor: 'citations',
        Cell: ({ cell: { value } }) => showCitations(value),
        sortType: 'sortByCitations',
        disableFilters: true,
        minWidth: 240,
        width: 400,
      },
    ],
    []
  )

  return (
    <>
      <Table columns={columns} data={data} />
    </>
  )
}

export default PhenotypeByInteraction
