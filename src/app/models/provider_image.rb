# == Schema Information
# Schema version: 20110302120000
#
# Table name: provider_images
#
#  id                 :integer         not null, primary key
#  image_id           :integer         not null
#  provider_id        :integer         not null
#  provider_image_key :string(255)
#  uuid               :string(255)
#  status             :string(255)
#

class ProviderImage < ActiveRecord::Base
  include ImageWarehouseObject

  belongs_to :provider
  belongs_to :image
  has_one :icicle, :dependent => :destroy

  validates_presence_of :provider_id
  validates_presence_of :image_id
  validates_uniqueness_of :uuid, :allow_nil => true
  validates_uniqueness_of :image_id, :scope => :provider_id

  STATE_QUEUED = 'queued'
  STATE_COMPLETED = 'completed'
  STATE_CANCELED = 'canceled'
  STATE_FAILED = 'failed'

  ACTIVE_STATES = [ STATE_QUEUED ]
  INACTIVE_STATES = [STATE_COMPLETED, STATE_FAILED, STATE_CANCELED]

  def after_update
    if self.status_changed? and self.status == STATE_COMPLETED
      safe_warehouse_sync
    end
  end

  def warehouse_bucket
    'provider_images'
  end

  def warehouse_sync
    bucket = warehouse.bucket(warehouse_bucket)
    raise WarehouseObjectNotFoundError unless bucket.include?(self.uuid)
    obj = bucket.object(self.uuid)
    attrs = obj.attrs([:uuid, :image, :icicle, :target_identifier])
    unless attrs[:image]
      raise "image uuid is not set"
    end
    unless img = Image.find_by_uuid(attrs[:image])
      raise "image with uuid #{attrs[:image]} not found"
    end
    begin
      self.icicle = Icicle.create_or_update(attrs[:icicle])
    rescue
      logger.error "Failed to fetch icicle '#{attrs[:icicle]}', setting icicle to nil: #{$!.message}"
    end
    self.image_id = img.id
    self.provider_image_key = attrs[:target_identifier]
  end
end
