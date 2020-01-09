require 'spec_helper'
require 'runners/corpus'

describe 'BSON Corpus spec tests' do

  BSON_CORPUS_TESTS.each do |path|
    basename = File.basename(path)
    # All of the tests in the failures subdir are failing apparently
    #basename = path.sub(/.*corpus-tests\//, '')

    spec = BSON::Corpus::Spec.new(path)

    context("(#{basename}): #{spec.description}") do

      spec.valid_tests&.each do |test|

        context("valid: #{test.description}") do

          let(:decoded_canonical_bson) do
            BSON::Document.from_bson(BSON::ByteBuffer.new(test.canonical_bson))
          end

          it 'round-trips canonical bson' do
            decoded_canonical_bson.to_bson.to_s.should == test.canonical_bson
          end

=begin
          it 'converts bson to canonical extended json' do
            pending
            raise NotImplementedError
          end
=end

          it 'converts bson to canonical extended json' do
            decoded_canonical_bson.as_extended_json.should == test.canonical_extjson_doc
          end

          if test.relaxed_extjson
            it 'converts bson to relaxed extended json' do
              decoded_canonical_bson.as_extended_json(relaxed: true).should == test.relaxed_extjson_doc
            end

            unless test.lossy?
              let(:parsed_relaxed_extjson) do
                BSON::ExtJSON.parse_obj(test.relaxed_extjson_doc)
              end

              it 'converts relaxed extended json to bson' do
                parsed_relaxed_extjson.to_bson.to_s.should == test.canonical_bson
              end
            end
          end

          if test.degenerate_bson

            let(:decoded_degenerate_bson) do
              BSON::Document.from_bson(BSON::ByteBuffer.new(test.degenerate_bson))
            end

            it 'round-trips degenerate bson to canonical bson' do
              decoded_degenerate_bson.to_bson.to_s.should == test.canonical_bson
            end
          end

          let(:parsed_canonical_extjson) do
            BSON::ExtJSON.parse_obj(test.canonical_extjson_doc)
          end

          unless test.lossy?
            it 'converts canonical extended json to bson' do
              parsed_canonical_extjson.to_bson.to_s.should == test.canonical_bson
            end
          end

        end
      end

      spec.decode_error_tests&.each do |test|

        context("decode error: #{test.description}") do

          let(:decoded_bson) do
            BSON::Document.from_bson(BSON::ByteBuffer.new(test.bson))
          end

          # Until bson-ruby gets an exception hierarchy, we can only rescue
          # the basic Exception here.
          # https://jira.mongodb.org/browse/RUBY-1806
          it 'raises an exception' do
            expect do
              decoded_bson
            end.to raise_error(Exception)
          end
        end
      end

      spec.parse_error_tests&.each do |test|

        context("parse error: #{test.description}") do

          let(:parsed_extjson) do
            BSON::ExtJSON.parse(test.string)
          end

          # Until bson-ruby gets an exception hierarchy, we can only rescue
          # the basic Exception here.
          # https://jira.mongodb.org/browse/RUBY-1806
          it 'raises an exception' do
            expect do
              parsed_extjson
            end.to raise_error(Exception)
          end
        end
      end
    end
  end
end
