module Lastic
  include Clauses
  
  describe Clauses, :to_h do
    let(:field){Field.new(:title)}
    let(:clause){field.term('Vonnegut')}
    let(:clause2){field.wildcard('Br?db?ry')}
    let(:clause3){field.regexp(/H.+nl.+n/)}
    
    it 'converts simple clauses' do
      expect(field.term('Alice In Wonderland').to_h).
        to eq( 'term' => {'title' => 'Alice In Wonderland'} )

      expect(field.terms('Alice In Wonderland', 'Slaughterhouse Five').to_h).
        to eq( 'terms' => {'title' => ['Alice In Wonderland', 'Slaughterhouse Five']} )

      expect(field.wildcard('Alice*').to_h).
        to eq( 'wildcard' => {'title' => 'Alice*'} )

      expect(field.exists.to_h).
        to eq( 'exists' => {'field' => 'title'} )

      expect(field.regexp(/[Aa]l?/).to_h).
        to eq('regexp' => {'title' => '[Aa]l?'})

      expect(field.range(gte: 1, lte: 2).to_h).
        to eq('range' => {'title' => {'gte' => 1, 'lte' => 2}})
    end

    it 'converts composite clauses' do
      expect(clause.and(clause2).to_h).
        to eq('and' => [clause.to_h, clause2.to_h])

      expect(clause.or(clause2).to_h).
        to eq('or' => [clause.to_h, clause2.to_h])

      expect(clause.not.to_h).
        to eq('not' => clause.to_h)

      expect(clause.must.should(clause2).to_h).
        to eq('bool' => {'must' => [clause.to_h], 'should' => [clause2.to_h]})

      expect(clause.filter(clause2).to_h).
        to eq('filtered' => {'query' => clause.to_h, 'filter' => clause2.to_h})

      expect(Clauses::Filtered.new(filter: clause2).to_h).
        to eq('filtered' => {'filter' => clause2.to_h})
    end

    it 'converts multi-field clauses' do
      expect(field.query_string('wtf').to_h).
        to eq('query_string' => {'fields' => ['title'], 'query' => 'wtf'})

      expect(field.simple_query_string('wtf').to_h).
        to eq('simple_query_string' => {'fields' => ['title'], 'query' => 'wtf'})
    end

    it 'converts empty multi-field clauses' do
      expect(QueryString.new(nil, 'wtf').to_h).
        to eq('query_string' => {'query' => 'wtf'})
    end

    it 'converts clauses with nested fields' do
      expect(Lastic.field('author.name').nested.term('Vonnegut').to_h).
        to eq( 'nested' => {
          'path' => 'author',
          'filter' => {
            'term' => {'author.name' => 'Vonnegut'}
          }
        })

      expect(Lastic.field('author.name').nested.term('Vonnegut').to_h(mode: :query)).
        to eq( 'nested' => {
          'path' => 'author',
          'query' => {
            'term' => {'author.name' => 'Vonnegut'}
          }
        })

      nested_filters = Lastic.field('author.name').nested.term('Vonnegut').
        filter(Lastic.field('author.dead').nested.term(true))

      expect(nested_filters.to_h).
        to eq(
          'filtered' => {
            'query' => {
              'nested' => {
                'path' => 'author',
                'query' => {
                  'term' => {'author.name' => 'Vonnegut'}
                }
              }
            },
            'filter' => {
              'nested' => {
                'path' => 'author',
                'filter' => {
                  'term' => {'author.dead' => true}
                }
              }
            },
          })

    end
  end
end
