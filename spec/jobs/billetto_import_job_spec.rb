
require "rails_helper"

RSpec.describe BillettoImportJob, type: :job do
  describe "#perform" do
    let(:importer) { instance_double(Billetto::Importer) }

    it "imports Billetto events" do
      result = {
        imported_count: 10,
        skipped_count: 2,
        total: 12,
        has_more: false
      }

      expect(Billetto::Importer)
        .to receive(:new)
        .and_return(importer)

      expect(importer)
        .to receive(:import)
        .and_return(result)

      expect(described_class.perform_now).to eq(result)
    end
  end
end
