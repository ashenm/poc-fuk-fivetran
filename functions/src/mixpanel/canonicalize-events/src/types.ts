export interface SourceEntry {
  properties: SourceProperties;
}

export interface SourceProperties {
  time: string;
}

export interface DestinationEntry extends SourceProperties {
  _fivetran_id: string; // primary key
}
